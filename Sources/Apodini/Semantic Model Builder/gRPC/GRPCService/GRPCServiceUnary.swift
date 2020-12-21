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
    func createUnaryHandler<C: Component>(for component: C, with context: Context) -> (GRPCRequest) -> EventLoopFuture<C.Response> {
        { (request: GRPCRequest) in
            let guardEventLoopFutures = self.processGuards(request, with: context)
            return EventLoopFuture<Void>
                .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
                .flatMap { _ in
                    request.enterRequestContext(with: component) { component in
                        var response: Encodable = component.handle()
                        for responseTransformer in context.get(valueFor: ResponseContextKey.self) {
                            response = request.enterRequestContext(with: responseTransformer()) { responseTransformer in
                                responseTransformer.transform(response: response)
                            }
                        }
                        // swiftlint:disable force_cast
                        return request.eventLoop.makeSucceededFuture(response as! C.Response)
                    }
                }
        }
    }

    /// Exposes a simple unary endpoint for the handle that the service was initialized with.
    /// The endpoint will be accessible at [host]/[serviceName]/[endpoint].
    /// - Parameters:
    ///     - endpoint: The name of the endpoint that should be exposed.
    func exposeUnaryEndpoint<C: Component>(name endpoint: String, for component: C, with context: Context) {
        let path = [
            Vapor.PathComponent(stringLiteral: serviceName),
            Vapor.PathComponent(stringLiteral: endpoint)
        ]

        // create the handler for the request
        let requestHandler = createUnaryHandler(for: component, with: context)

        app.on(.POST, path) { (vaporRequest: Vapor.Request) -> EventLoopFuture<Vapor.Response> in
            let promise = vaporRequest.eventLoop.makePromise(of: Vapor.Response.self)
            vaporRequest.body.collect().whenSuccess { _ in
                let request = GRPCRequest(vaporRequest)
                let response: EventLoopFuture<C.Response> = requestHandler(request)
                let result = response.flatMapThrowing { self.encodeResponse($0) }

                promise.completeWith(result)
            }
            return promise.futureResult
        }
    }
}
