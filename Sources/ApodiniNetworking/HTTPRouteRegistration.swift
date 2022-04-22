//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIO
import enum Apodini.CommunicationPattern


/// A type on which HTTP routes can be registered
public protocol HTTPRoutesBuilder {
    /// Registers a new route on the HTTP server
    /// - parameter method: The route's HTTP method
    /// - parameter path: The route's path, expressed as a collection of path components
    /// - parameter handler: A closure which will be called to handle requests reaching this route.
    /// - throws: If the routes builder was unable to register the route, for example because another conflicting route already exists
    func registerRoute(
        _ method: HTTPMethod,
        _ path: [HTTPPathComponent],
        _ expectedCommunicationPattern: CommunicationPattern?,
        handler: @escaping (HTTPRequest) -> HTTPResponseConvertible
    ) throws
//    /// Registers a new route on the HTTP server
//    /// - parameter method: The route's HTTP method
//    /// - parameter path: The route's path, expressed as a collection of path components
//    /// - parameter responder: The responder object responsible for responding to requests reaching this route
//    /// - throws: If the routes builder was unable to register the route, for example because another conflicting route already exists
//    func registerRoute(_ method: HTTPMethod, _ path: [HTTPPathComponent], responder: HTTPResponder) throws
}


public extension HTTPRoutesBuilder {
//    @_disfavoredOverload
//    func registerRoute(
//        _ method: HTTPMethod,
//        _ path: [HTTPPathComponent],
//        _ expectedCommunicationPattern: CommunicationPattern? = nil,
//        handler: @escaping (HTTPRequest) -> HTTPResponseConvertible
//    ) throws {
//        try registerRoute(method, path, expectedCommunicationPattern, handler: handler)
//    }
    
    /// Registers a new route on the HTTP server
    /// - parameter method: The route's HTTP method
    /// - parameter path: The route's path, expressed as a collection of path components
    /// - parameter handler: A closure which will be called to handle requests reaching this route.
    /// - throws: If the routes builder was unable to register the route, for example because another conflicting route already exists
    func registerRoute(
        _ method: HTTPMethod,
        _ path: [HTTPPathComponent],
        _ expectedCommunicationPattern: CommunicationPattern? = nil,
        handler: @escaping (HTTPRequest) throws -> HTTPResponseConvertible
    ) throws {
        try registerRoute(method, path, expectedCommunicationPattern) { request -> HTTPResponseConvertible in
            do {
                return try handler(request)
            } catch {
                return request.eventLoop.makeFailedFuture(error) as EventLoopFuture<HTTPResponse>
            }
        }
    }
    
    /// Registers a new route on the HTTP server
    /// - parameter method: The route's HTTP method
    /// - parameter path: The route's path, expressed as a collection of path components
    /// - parameter responder: The responder object responsible for responding to requests reaching this route
    /// - throws: If the routes builder was unable to register the route, for example because another conflicting route already exists
    func registerRoute(
        _ method: HTTPMethod,
        _ path: [HTTPPathComponent],
        _ expectedCommunicationPattern: CommunicationPattern? = nil,
        responder: HTTPResponder
    ) throws {
        try registerRoute(method, path, expectedCommunicationPattern) { request -> HTTPResponseConvertible in
            responder.respond(to: request)
        }
    }
}
