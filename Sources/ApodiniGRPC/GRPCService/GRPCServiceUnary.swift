//
//  GRPCServiceUnary.swift
//  
//
//  Created by Moritz Schüll on 20.12.20.
//

import Foundation
import Apodini
@_implementationOnly import Vapor

// MARK: Unary request handler
extension GRPCService {
    func createUnaryHandler<C: ConnectionContext>(context: C)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> where C.Exporter == GRPCInterfaceExporter {
        { (request: Vapor.Request) in
            if !self.contentTypeIsSupported(request: request) {
                return request.eventLoop.makeFailedFuture(GRPCError.unsupportedContentType(
                    "Content type is currently not supported by Apodini GRPC exporter. Use Protobuffers instead."
                ))
            }

            var context = context
            
            let promise = request.eventLoop.makePromise(of: Vapor.Response.self)
            request.body.collect().whenSuccess { _ in
                guard let byteBuffer = request.body.data,
                      let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
                    return promise.fail(GRPCError.payloadReadError("Cannot read data from the request-payload"))
                }

                // retrieve all the GRPC messages that were delivered in the
                // request payload. Since this is a unary endpoint, it
                // should be one at max (so we discard potential following messages).
                let message = self.getMessages(from: data).first ?? GRPCMessage.defaultMessage

                let response = context.handle(request: message, eventLoop: request.eventLoop, final: true)
                let result = response.map { encodableAction -> Vapor.Response in
                    switch encodableAction {
                    case let .send(element),
                         let .final(element):
                        return self.makeResponse(element)
                    case .nothing, .end:
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
    func exposeUnaryEndpoint<C: ConnectionContext>(name endpoint: String,
                                                   context: C) throws where C.Exporter == GRPCInterfaceExporter {
        if methodNames.contains(endpoint) {
            throw GRPCServiceError.endpointAlreadyExists
        }
        methodNames.append(endpoint)

        let path = [
            Vapor.PathComponent(stringLiteral: serviceName),
            Vapor.PathComponent(stringLiteral: endpoint)
        ]

        app.on(.POST, path) { request in
            self.createUnaryHandler(context: context)(request)
        }
    }
}