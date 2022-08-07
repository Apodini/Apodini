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
import Logging

extension HTTPInterfaceExporter {
    func http1RequestSequence<H: Handler>(
        _ request: HTTPRequest,
        _ defaultValues: DefaultValueStore,
        _ endpoint: Endpoint<H>
    ) throws -> AnyAsyncSequence<DefaultValueStore.DefaultInsertingRequest> {
        let strategy = multiInputDecodingStrategy(for: endpoint)
        
        guard let requestCount = try configuration.decoder.decode(
            ArrayCount.self,
            from: request.bodyStorage.getFullBodyData() ?? .init()
        ).count else {
            throw ApodiniError(
                type: .badInput,
                reason: "Expected array at top level of body.",
                description: "Input for client side steaming endpoints must be an array at top level.")
        }
        
        return Array(0..<requestCount)
            .asAsyncSequence
            .map { index in
                (request, (request, index))
            }
            .decode(using: strategy, with: request.eventLoop)
            .insertDefaults(with: defaultValues)
            .typeErased
    }
    
    func http2RequestSequence<H: Handler>(
        _ request: HTTPRequest,
        _ defaultValues: DefaultValueStore,
        _ endpoint: Endpoint<H>
    ) throws -> AnyAsyncSequence<DefaultValueStore.DefaultInsertingRequest> {
        let strategy = dataFrameDecodingStrategy(for: endpoint)
        
        guard case .stream(let stream) = request.bodyStorage else {
            throw BodyStorageTypeError.notStream
        }
        
        return HTTPRequestStreamAsyncSequence(stream)
            .map { data in
                (request, data)
            }
            .decode(using: strategy, with: request.eventLoop)
            .insertDefaults(with: defaultValues)
            .typeErased
    }
}

extension AsyncSequence {
    func http1ResponseSequence<H: Handler>(
        _ request: HTTPRequest,
        _ encoder: AnyEncoder,
        _ endpoint: Endpoint<H>
    ) -> EventLoopFuture<HTTPResponse> where Element == Apodini.Response<H.Response.Content> {
        return self.collect()
            .map { (responses: [Apodini.Response<H.Response.Content>]) -> HTTPResponse in
                let status: Status? = responses.last?.status
                let information: InformationSet = responses.last?.information ?? []
                let contents: [H.Response.Content] = responses.compactMap { response in
                    response.content
                }
                var httpHeaders = HTTPHeaders(information)
                
                var body: ByteBuffer
                let blobContents = contents.compactMap { $0 as? Blob }
                if let first = blobContents.first {
                    // content type is blob
                    httpHeaders[.contentType] = first.type
                    body = ByteBuffer()
                    for blob in blobContents {
                        body.writeImmutableBuffer(blob.byteBuffer)
                    }
                } else {
                    body = ByteBuffer(data: try encoder.encode(contents))
                }
                
                return HTTPResponse(
                    version: request.version,
                    status: HTTPResponseStatus(status ?? .ok),
                    headers: httpHeaders,
                    bodyStorage: .buffer(initialValue: body)
                )
            }
            .firstFuture(on: request.eventLoop)
    }
    
    func http2ResponseSequence<H: Handler>(
        _ request: HTTPRequest,
        _ logger: Logger,
        _ encoder: AnyEncoder,
        _ endpoint: Endpoint<H>
    ) -> EventLoopFuture<HTTPResponse> where Element == Apodini.Response<H.Response.Content> {
        let httpResponseStream = BodyStorage.Stream()
        
        return self.firstFutureAndForEach(
            on: request.eventLoop,
            objectsHandler: { (response: Apodini.Response<H.Response.Content>) -> Void in
                defer {
                    if response.connectionEffect == .close {
                        httpResponseStream.close()
                    }
                }
                do {
                    let data: Data
                    if let content = response.content {
                        if let blobContent = content as? Blob {
                            precondition(blobContent.byteBuffer.readerIndex == 0)
                            data = blobContent.byteBuffer.getAllData() ?? Data()
                        } else {
                            data = try encoder.encode(content)
                        }
                    } else {
                        data = Data()
                    }
                    
                    httpResponseStream.write(Int32(data.count))
                    httpResponseStream.write(data)
                } catch {
                    // Error encoding the response data
                    endpoint[ErrorForwarder.self].forward(error)
                    logger.error("Error encoding part of response: \(error)")
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

enum BodyStorageTypeError: Error, CustomStringConvertible {
    case notStream
    
    public var description: String {
        switch self {
        case .notStream:
            return "A .stream BodyStorage must be supplied!"
        }
    }
}
