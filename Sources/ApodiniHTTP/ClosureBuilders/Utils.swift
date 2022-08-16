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
    func singleDecodingSequence<H: Handler>(
        _ request: HTTPRequest,
        _ defaultValues: DefaultValueStore,
        _ endpoint: Endpoint<H>
    ) -> AnyAsyncSequence<DefaultValueStore.DefaultInsertingRequest> {
        let strategy = singleInputDecodingStrategy(for: endpoint)
        
        return [request]
            .asAsyncSequence
            .decode(using: strategy, with: request.eventLoop)
            .insertDefaults(with: defaultValues)
            .typeErased
    }
    
    func singleLengthPrefixedDecodingSequence<H: Handler>(
        _ request: HTTPRequest,
        _ defaultValues: DefaultValueStore,
        _ endpoint: Endpoint<H>
    ) throws -> AnyAsyncSequence<DefaultValueStore.DefaultInsertingRequest> {
        try lengthPrefixDecodingSequence(request, defaultValues, endpoint)
            .firstAndThenError(StreamingError.moreThanOneRequest)
            .typeErased
    }
    
    func arrayDecodingSequence<H: Handler>(
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
    
    func lengthPrefixDecodingSequence<H: Handler>(
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
    func encodeAsHTTPResponse<E: Encodable>(
        _ request: HTTPRequest,
        _ encoder: AnyEncoder
    ) -> EventLoopFuture<HTTPResponse> where Element == Apodini.Response<E> {
        self.map { (response: Apodini.Response<E>) -> HTTPResponse in
            let information: InformationSet = response.information
            var httpHeaders = HTTPHeaders(information)
            
            var body: ByteBuffer
            if let blobContent = response.content as? Blob {
                // content type is blob
                httpHeaders[.contentType] = blobContent.type
                body = ByteBuffer()
                body.writeImmutableBuffer(blobContent.byteBuffer)
            } else {
                body = ByteBuffer(data: try encoder.encode(response.content))
            }
            
            return HTTPResponse(
                version: request.version,
                status: HTTPResponseStatus(response.status ?? .ok),
                headers: httpHeaders,
                bodyStorage: .buffer(initialValue: body)
            )
        }
        .firstFuture(on: request.eventLoop)
        .map { response in
            precondition(response != nil)
            response?.setContentLengthForCurrentBody()
            return response ?? HTTPResponse(version: request.version, status: .ok, headers: [:])
        }
    }
    
    func encodeAsArray<H: Handler>(
        _ request: HTTPRequest,
        _ encoder: AnyEncoder,
        _ endpoint: Endpoint<H>
    ) -> EventLoopFuture<HTTPResponse> where Element == Apodini.Response<H.Response.Content> {
        self.collect()
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
            .unwrap(orError: StreamingError.noResponse)
    }
    
    func encodeForHTTP2Streaming<H: Handler>(
        _ request: HTTPRequest,
        _ logger: Logger,
        _ encoder: AnyEncoder,
        _ endpoint: Endpoint<H>
    ) -> EventLoopFuture<HTTPResponse> where Element == Apodini.Response<H.Response.Content> {
        let httpResponseStream = BodyStorage.Stream()
        
        return self
            .map { (response: Apodini.Response<H.Response.Content>) -> Apodini.Response<Data> in
                response.map { content in
                    if let blobContent = content as? Blob {
                        precondition(blobContent.byteBuffer.readerIndex == 0)
                        return blobContent.byteBuffer.getAllData() ?? Data()
                    } else {
                        do {
                            return try encoder.encode(content)
                        } catch {
                            // Error encoding the response data
                            endpoint[ErrorForwarder.self].forward(error)
                            logger.error("Error encoding part of response: \(error)")
                            return Data()
                        }
                    }
                }
            }
            .replaceErrorAndEnd { error in
                (.send(error.standardMessage.data(using: .utf8) ?? Data()), .final())
            }
            .firstFutureAndForEach(
                on: request.eventLoop,
                objectsHandler: { (response: Apodini.Response<Data>) -> Void in
                    // TODO is this correct? What about .final responses?
                    if response.connectionEffect == .close {
                        httpResponseStream.close()
                        return
                    }
                    defer {
                        if response.connectionEffect == .close {
                            httpResponseStream.close()
                        }
                    }
                    
                    let data = response.content ?? Data()
                    
                    httpResponseStream.write(Int32(data.count))
                    httpResponseStream.write(data)
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
    
    var description: String {
        switch self {
        case .notStream:
            return "A .stream BodyStorage must be supplied!"
        }
    }
}

enum StreamingError: Error, CustomStringConvertible {
    case noResponse
    case moreThanOneRequest
    case moreThanOneResponse
    
    var description: String {
        switch self {
        case .noResponse:
            return "Nil response found!"
        case .moreThanOneRequest:
            return "More than one request found although only one is allowed!"
        case .moreThanOneResponse:
            return "More than one response found although only one is allowed!"
        }
    }
}
