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
import ApodiniNetworking


extension HTTPInterfaceExporter {
    func buildServiceSideStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> {
        let encoder = configuration.encoder
        return _buildServiceSideStreamingClosure(for: endpoint, using: defaultValues) { response -> Data? in
            if let response = response {
                return try encoder.encode(response)
            } else {
                return nil
            }
        }
    }
    
    
    func buildServiceSideStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> where H.Response.Content == Blob {
        _buildServiceSideStreamingClosure(for: endpoint, using: defaultValues) { (response: Blob?) -> Data? in
            precondition(response?.byteBuffer.readerIndex == 0)
            return response?.byteBuffer.getAllData()
        }
    }
    
    
    private func _buildServiceSideStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore,
        encodeResponse: @escaping (H.Response.Content?) throws -> Data?
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        let abortAnyError = ErrorForwardingResultTransformer(
            wrapped: AbortTransformer<H>(),
            forwarder: endpoint[ErrorForwarder.self]
        )
        let factory = endpoint[DelegateFactory<H, HTTPInterfaceExporter>.self]
        
        return { [unowned self] (request: HTTPRequest) throws -> EventLoopFuture<HTTPResponse> in
            let delegate = factory.instance()
            let httpResponseStream = BodyStorage.Stream()
            return [request]
                .asAsyncSequence
                .decode(using: strategy, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .cache()
                .forwardDecodingErrors(with: endpoint[ErrorForwarder.self])
                .subscribe(to: delegate)
                .evaluate(on: delegate)
                .transform(using: abortAnyError)
                .cancelIf { $0.connectionEffect == .close }
                .firstFutureAndForEach(
                    on: request.eventLoop,
                    objectsHandler: { (response: Apodini.Response<H.Response.Content>) -> Void in
                        defer {
                            if response.connectionEffect == .close {
                                httpResponseStream.close()
                            }
                        }
                        do {
                            if let data = try encodeResponse(response.content) {
                                httpResponseStream.write(Int32(data.count))
                                httpResponseStream.write(data)
                            }
                        } catch {
                            // Error encoding the response data
                            endpoint[ErrorForwarder.self].forward(error)
                            self.logger.error("Error encoding part of response: \(error)")
                        }
                    }
                )
                .map { firstResponse -> HTTPResponse in
                    HTTPResponse(
                        version: request.version,
                        status: HTTPResponseStatus(firstResponse?.status ?? .ok),
                        headers: HTTPHeaders(firstResponse?.information ?? []),
                        bodyStorage: .stream(httpResponseStream)
                    )
                }
        }
    }
}
