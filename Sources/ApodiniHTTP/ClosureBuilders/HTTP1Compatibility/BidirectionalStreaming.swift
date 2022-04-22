//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniExtension
import ApodiniHTTPProtocol
import ApodiniNetworking


extension HTTPInterfaceExporter {
    func buildBidirectionalStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> {
        let encoder = configuration.encoder
        return _buildBidirectionalStreamingClosure(for: endpoint, using: defaultValues) { responses, _ in
            ByteBuffer(data: try encoder.encode(responses))
        }
    }
    
    func buildBidirectionalStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> where H.Response.Content == Blob {
        _buildBidirectionalStreamingClosure(for: endpoint, using: defaultValues) { (responses: [Blob], headers: inout HTTPHeaders) in
            if let mediaType = responses.first?.type {
                headers[.contentType] = mediaType
            }
            var data = ByteBuffer()
            for response in responses {
                data.writeImmutableBuffer(response.byteBuffer)
            }
            return data
        }
    }
    
    
    private func _buildBidirectionalStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore,
        encodeResponse: @escaping ([H.Response.Content], _ httpResponseHeaders: inout HTTPHeaders) throws -> ByteBuffer
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> {
        let strategy = multiInputDecodingStrategy(for: endpoint)
        let abortAnyError = ErrorForwardingResultTransformer(
            wrapped: AbortTransformer<H>(),
            forwarder: endpoint[ErrorForwarder.self]
        )
        let factory = endpoint[DelegateFactory<H, HTTPInterfaceExporter>.self]
        return { [unowned self] (request: HTTPRequest) in // swiftlint:disable:this closure_body_length
            do {
                guard let requestCount = try configuration.decoder.decode(
                    ArrayCount.self,
                    from: request.bodyStorage.getFullBodyData() ?? .init()
                ).count else {
                    throw ApodiniError(
                        type: .badInput,
                        reason: "Expected array at top level of body.",
                        description: "Input for client side steaming endpoints must be an array at top level.")
                }
                let delegate = factory.instance()
                return Array(0..<requestCount)
                    .asAsyncSequence
                    .map { index in
                        (request, (request, index))
                    }
                    .decode(using: strategy, with: request.eventLoop)
                    .insertDefaults(with: defaultValues)
                    .validateParameterMutability()
                    .cache()
                    .forwardDecodingErrors(with: endpoint[ErrorForwarder.self])
                    .subscribe(to: delegate)
                    .evaluate(on: delegate)
                    .transform(using: abortAnyError)
                    .cancelIf { $0.connectionEffect == .close }
                    .collect()
                    .map { (responses: [Apodini.Response<H.Response.Content>]) -> HTTPResponse in
                        let status: Status? = responses.last?.status
                        let information: InformationSet = responses.last?.information ?? []
                        let content: [H.Response.Content] = responses.compactMap { response in
                            response.content
                        }
                        var httpHeaders = HTTPHeaders(information)
                        let body = try encodeResponse(content, &httpHeaders)
                        return HTTPResponse(
                            version: request.version,
                            status: HTTPResponseStatus(status ?? .ok),
                            headers: httpHeaders,
                            bodyStorage: .buffer(initialValue: body)
                        )
                    }
                    .firstFuture(on: request.eventLoop)
                    .map { optionalResponse in
                        precondition(optionalResponse != nil)
                        return optionalResponse ?? HTTPResponse(version: request.version, status: .ok, headers: [:])
                    }
            } catch {
                endpoint[ErrorForwarder.self].forward(error)
                throw error
            }
        }
    }
}
