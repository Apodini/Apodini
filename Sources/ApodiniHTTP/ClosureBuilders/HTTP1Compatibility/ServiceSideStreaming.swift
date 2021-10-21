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


extension AsyncSequence {
    /// Returns an `EventLoopFuture` which will fulfill with the first element in the sequence, and also calls the specified closure once with every element in the sequence
    func lk_firstFuture(on eventLoop: EventLoop, remainingObjectsHandler: @escaping (Element) -> Void) -> EventLoopFuture<Element?> {
        let promise = eventLoop.makePromise(of: Element?.self)
        Task {
            var idx = 0
            for try await element in self {
                if idx == 0 {
                    promise.succeed(element)
                }
                idx += 1
                remainingObjectsHandler(element)
            }
            if idx == 0 {
                promise.succeed(nil)
            }
        }
        return promise.futureResult
    }
}


extension Exporter {
    func buildServiceSideStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> {
        let encoder = endpoint[Context.self].get(valueFor: ResponseEncoderHandlerMetadata.Key.self) ?? configuration.encoder
        return _buildServiceSideStreamingClosure(for: endpoint, using: defaultValues) { response -> Data? in
            guard let response = response else { return nil }
            return try encoder.encode(response)
        }
    }
    
    
    func buildServiceSideStreamingClosure<H: Handler>(
        for endpoint: Endpoint<H>,
        using defaultValues: DefaultValueStore
    ) -> (HTTPRequest) throws -> EventLoopFuture<HTTPResponse> where H.Response.Content == Blob {
        return _buildServiceSideStreamingClosure(for: endpoint, using: defaultValues) { (response: Blob?) -> Data? in
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
        let abortAnyError = AbortTransformer<H>()
        let factory = endpoint[DelegateFactory<H, Exporter>.self]
        
        return { (request: HTTPRequest) throws -> EventLoopFuture<HTTPResponse> in
            let delegate = factory.instance()
            let httpResponseStream = BodyStorage.Stream()
            httpResponseStream.debugName = "HTTPServerResponse"
            return [request]
                .asAsyncSequence
                .decode(using: strategy, with: request.eventLoop)
                .insertDefaults(with: defaultValues)
                .cache()
                .subscribe(to: delegate)
                .evaluate(on: delegate)
                .transform(using: abortAnyError)
                .cancel(if: { $0.connectionEffect == .close })
                .lk_firstFuture(
                    on: request.eventLoop,
                    remainingObjectsHandler: { (response: Apodini.Response<H.Response.Content>) -> Void in
                        defer {
                            if response.connectionEffect == .close {
                                httpResponseStream.close()
                            }
                        }
                        do {
                            if let data = try encodeResponse(response.content) {
                                httpResponseStream.write(data)
                            }
                        } catch {
                            // Error encoding the response data
                            // TODO how should this be handled? Abort the entire reesponse?
                        }
                    }
                )
                .map { firstResponse -> HTTPResponse in
                    return HTTPResponse(
                        version: request.version,
                        status: HTTPResponseStatus(firstResponse?.status ?? .ok), // TODO is this a reasonable default?,
                        headers: HTTPHeaders(firstResponse?.information ?? []),
                        bodyStorage: .stream(httpResponseStream)
                    )
                }
        }
    }
}
