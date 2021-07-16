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
@_implementationOnly import Vapor

// MARK: Unary request handler
extension GRPCService {
    func createUnaryHandler<H: Handler>(handler: H,
                                        strategy: AnyDecodingStrategy<GRPCMessage>,
                                        defaults: DefaultValueStore) -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        { (request: Vapor.Request) in
            if !self.contentTypeIsSupported(request: request) {
                return request.eventLoop.makeFailedFuture(GRPCError.unsupportedContentType(
                    "Content type is currently not supported by Apodini GRPC exporter. Use Protobuffers instead."
                ))
            }
            
            var delegate = Delegate(handler, .required)

            let promise = request.eventLoop.makePromise(of: Vapor.Response.self)
            request.body.collect().whenSuccess { _ in
                let byteBuffer = request.body.data ?? ByteBuffer()
                let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) ?? Data()
                
                // retrieve all the GRPC messages that were delivered in the
                // request payload. Since this is a unary endpoint, it
                // should be one at max (so we discard potential following messages).
                let message = self.getMessages(from: data, remoteAddress: request.remoteAddress).first ?? GRPCMessage.defaultMessage

                let basis = DefaultRequestBasis(base: message, remoteAddress: message.remoteAddress, information: request.information)
                
                let response: EventLoopFuture<Apodini.Response<H.Response.Content>> = strategy
                    .decodeRequest(from: message, with: basis, with: request.eventLoop)
                    .insertDefaults(with: defaults)
                    .cache()
                    .evaluate(on: &delegate)
                
                let result = response.map { response -> Vapor.Response in
                    switch response.content {
                    case let .some(content):
                        return self.makeResponse(content)
                    case .none:
                        return self.makeResponse()
                    }
                }

                promise.completeWith(result)
            }
            return promise.futureResult
        }
    }

    /// Exposes a simple unary endpoint for the handle that the service was initialized with.
    /// The endpoint will be accessible at [host]/[serviceName]/[endpoint].
    /// - Parameters:
    ///     - endpoint: The name of the endpoint that should be exposed.
    func exposeUnaryEndpoint<H: Handler>(name methodName: String? = nil, _ endpoint: Endpoint<H>, strategy: AnyDecodingStrategy<GRPCMessage>) throws {
        let methodName = methodName ?? gRPCMethodName(from: endpoint)
        
        if methodNames.contains(methodName) {
            throw GRPCServiceError.endpointAlreadyExists
        }
        methodNames.append(methodName)

        let path = [
            Vapor.PathComponent(stringLiteral: serviceName),
            Vapor.PathComponent(stringLiteral: methodName)
        ]

        vaporApp.on(.POST, path) { request in
            self.createUnaryHandler(handler: endpoint.handler,
                                    strategy: strategy,
                                    defaults: endpoint[DefaultValueStore.self])(request)
        }
    }
}
