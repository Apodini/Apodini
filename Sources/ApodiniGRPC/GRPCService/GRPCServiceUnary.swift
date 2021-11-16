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


// MARK: Unary request handler
extension GRPCService {
    func createUnaryHandler<H: Handler>(
        factory: DelegateFactory<H, GRPCInterfaceExporter>,
        strategy: AnyDecodingStrategy<GRPCMessage>,
        defaults: DefaultValueStore
    ) -> (HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        { (request: HTTPRequest) in
            guard self.contentTypeIsSupported(request: request) else {
                return request.eventLoop.makeFailedFuture(GRPCError.unsupportedContentType(
                    "Content type is currently not supported by Apodini GRPC exporter. Use Protobuffers instead."
                ))
            }
            
            let delegate = factory.instance()
            let promise = request.eventLoop.makePromise(of: HTTPResponse.self)
            
            request.bodyStorage.collect(on: request.eventLoop).whenSuccess { byteBuffer in
                let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) ?? Data()
                
                // retrieve all the GRPC messages that were delivered in the
                // request payload. Since this is a unary endpoint, it
                // should be one at max (so we discard potential following messages).
                let message = self.getMessages(from: data, remoteAddress: request.remoteAddress).first ?? GRPCMessage.defaultMessage

                let basis = DefaultRequestBasis(
                    base: message,
                    remoteAddress: message.remoteAddress,
                    information: request.information.merge(with: Self.getLoggingMetadataInformation(message))
                )
                
                let response: EventLoopFuture<Apodini.Response<H.Response.Content>> = strategy
                    .decodeRequest(from: message, with: basis, with: request.eventLoop)
                    .insertDefaults(with: defaults)
                    .cache()
                    .evaluate(on: delegate)
                
                let result = response.map { response -> HTTPResponse in
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

        app.httpServer.registerRoute(.POST, [.verbatim(serviceName), .verbatim(methodName)]) { request in
            self.createUnaryHandler(
                factory: endpoint[DelegateFactory<H, GRPCInterfaceExporter>.self],
                strategy: strategy,
                defaults: endpoint[DefaultValueStore.self]
            )(request)
        }
    }
}
