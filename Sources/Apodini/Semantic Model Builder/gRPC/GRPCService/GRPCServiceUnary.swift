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
    func createUnaryHandler(requestHandler: @escaping RequestHandler) -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        { (vaporRequest: Vapor.Request) in
            let promise = vaporRequest.eventLoop.makePromise(of: Vapor.Response.self)
            vaporRequest.body.collect().whenSuccess { _ in
                let request = GRPCRequest(vaporRequest)
                let response: EventLoopFuture<Encodable> = requestHandler(request)
                let result = response.flatMapThrowing { self.encodeResponse($0) }

                promise.completeWith(result)
            }
            return promise.futureResult
        }
    }

    /// Exposes a simple unary endpoint for the handle that the service was initialized with.
    /// The endpoint will be accessible at [host]/[serviceName]/[endpoint].
    /// - Parameters:
    ///     - endpoint: The name of the endpoint that should be exposed.
    func exposeUnaryEndpoint(name endpoint: String,
                             requestHandler: @escaping RequestHandler) {
        let path = [
            Vapor.PathComponent(stringLiteral: serviceName),
            Vapor.PathComponent(stringLiteral: endpoint)
        ]

        app.on(.POST, path) { request in
            self.createUnaryHandler(requestHandler: requestHandler)(request)
        }
    }
}
