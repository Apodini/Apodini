//
//  GRPCServiceUnary.swift
//  
//
//  Created by Moritz Schüll on 20.12.20.
//

import Foundation
@_implementationOnly import Vapor

// MARK: Unary request handler
extension GRPCService {
    func createUnaryHandler<C: ConnectionContext>(context: C)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> where C.Exporter == GRPCInterfaceExporter {
        { (request: Vapor.Request) in
            var context = context
            
            let promise = request.eventLoop.makePromise(of: Vapor.Response.self)
            request.body.collect().whenSuccess { _ in
                let response = context.handle(request: request)
                let result = response.map { encodableAction -> Vapor.Response in
                    switch encodableAction {
                    case let .send(element),
                         let .final(element),
                         let .automatic(element):
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
                                                   context: C) where C.Exporter == GRPCInterfaceExporter {
        let path = [
            Vapor.PathComponent(stringLiteral: serviceName),
            Vapor.PathComponent(stringLiteral: endpoint)
        ]

        app.on(.POST, path) { request in
            self.createUnaryHandler(context: context)(request)
        }
    }
}
