//
//  GRPCMiddleware.swift
//
//
//  Created by Michael Schlicker on 13.12.19.
//

import Foundation
import Vapor

/**
 A `GRPCMiddleware` instance can be integrated as a middleware into the Vapor application like this:

    `app.middleware.use(GRPCMiddleware())`

 This middleware checks the content-type of incoming requests and in handles them in case of a gRPC request or forwards them to the next middleware.
 It implements Vapor's `Moiddleware` protocol which requires it to implement a `respond`function.
 */

public class GRPCMiddleware: Middleware {

    // MARK: Private Variables

    /// A dictionary containing all used `GRPCService`s with the service names as their keys.
    private var services: [String: GRPCService] = [:]

    // MARK: Initializers

    /**
    Initializes a `GRPCMiddleware` using the `GRPCServices` passed as an argument.
    - parameter services: `GRPCService` instances that should be included for routing.
    */
    public init(services: [GRPCService] = []) {
        services.forEach(addService)
    }

    // MARK: Public Methods

    /**
     Adds `GRPCService` instance to the `services` dictionary.

     - parameter service: `GRPCService` instance that should be used by the middleware.
     */
    public func addService(_ service: GRPCService) {
        services[service.serviceName] = service
    }

    /**
    Handles to incoming Vapor `Request`s and responds with an `EventLoopFuture` of a Vapor `Response`.

     This method starts out by checking if the incoming request can be handeled by this middleware or should be forwarded to the next responder.
     It can handle the incoming request if its content-type is `application/grpc` and the `getCallHandler` method returns a call handler.
     If this middleware can handle the request it returns the `response` of the call handler which is of type`EventLoopFuture<Response>`.

    - parameter request: Incoming Vapor `Request` instance that should be handled.
    - parameter next: `Responder`instance that either is the next middleware or the Vapor router. This one is used if the incoming request can't be handled by this middleware.
    - returns: An `EventLoopFuture` of a Vapor `Response` that will be sent to the client by the Vapor stack.
    */
    public func respond(to request: Vapor.Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard request.headers["content-type"].contains("application/grpc"),
            let callHandler = self.getCallHandler(request: request) else {
            return next.respond(to: request)
        }
        return callHandler.response
    }

    /**
    Returns the associated call handler for an incoming Vapor `Request`.

     This method decodes the in the url encoded service name and procedure call name.
     Next it gets the called service from the middleware's services dicitionary using the decoded service name as its key.
     It then calls the `handleMethod` method of the called service which returns the call handler associated with the passed `methodName`.

    - parameter request: Incoming Vapor `Request` that contains the called service and procedure name.
    - returns: An `AnyCallHandler` in case a matching call handler is found otherwise it returns `nil`.
    */
    func getCallHandler(request: Vapor.Request) -> AnyCallHandler? {
        let components = request.url.path.components(separatedBy: "/")
        guard components.count >= 3 else { return nil }
        let serviceName = components[1]
        let service = services[serviceName]
        let methodName = components[2]

        return service?.handleMethod(methodName: methodName, vaporRequest: request)
    }
}
