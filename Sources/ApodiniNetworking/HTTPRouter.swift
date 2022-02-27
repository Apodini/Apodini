//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO
import NIOHTTP1
import Logging
import Foundation
import enum Apodini.CommunicationPattern


public enum HTTPPathComponent: Equatable, ExpressibleByStringLiteral {
    case constant(String)
    case namedParameter(String)
    case wildcardSingle(String?)
    case wildcardMultiple(String?)
    
    public init(stringLiteral value: String) {
        self.init(string: value)
    }
    
    public init<S: StringProtocol>(string: S) {
        if string.hasPrefix(":") {
            self = .namedParameter(.init(string.dropFirst()))
        } else if string == "*" {
            self = .wildcardSingle(nil)
        } else if string.hasPrefix("*[") {
            precondition(string.hasSuffix("]"), "Invalid wildcard pattern")
            let name = String(string.dropFirst(2).dropLast())
            precondition(!name.isEmpty, "Invalid wildcard name")
            self = .wildcardSingle(name)
        } else if string == "**" {
            self = .wildcardMultiple(nil)
        } else if string.hasPrefix("**[") {
            precondition(string.hasSuffix("]"), "Invalid wildcard pattern")
            let name = String(string.dropFirst(3).dropLast())
            precondition(!name.isEmpty, "Invalid wildcard name")
            self = .wildcardMultiple(name)
        } else {
            self = .constant(String(string))
        }
    }
    
    /// Whether this path component is a `constant(_)` path component
    public var isConstant: Bool {
        switch self {
        case .constant:
            return true
        case .namedParameter, .wildcardSingle, .wildcardMultiple:
            return false
        }
    }
}


extension Array: ExpressibleByStringLiteral, ExpressibleByExtendedGraphemeClusterLiteral, ExpressibleByUnicodeScalarLiteral
where Element == HTTPPathComponent {
    public typealias StringLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType.ExtendedGraphemeClusterLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType.UnicodeScalarLiteralType
    
    public init(stringLiteral value: String) {
        self = value.httpPathComponents
    }
}


extension Array where Element == HTTPPathComponent {
    /// Constructs an array of path components from a path string
    public init(_ string: String) {
        self = string.split(separator: "/").map { .init(string: $0) }
    }
    
    
    /// Constructs a string from the path components
    public var httpPathString: String {
        guard !isEmpty else {
            return "/"
        }
        return self.reduce(into: "") { partialResult, pathComponent in
            partialResult.append("/")
            switch pathComponent {
            case .constant(let value):
                partialResult.append(value)
            case .namedParameter(let name):
                partialResult.append(":\(name)")
            case .wildcardSingle(nil):
                partialResult.append("*")
            case .wildcardSingle(.some(let name)):
                partialResult.append("*[\(name)]")
            case .wildcardMultiple(nil):
                partialResult.append("**")
            case .wildcardMultiple(.some(let name)):
                partialResult.append("**[\(name)]")
            }
        }
    }
    
    
    /// Returns the furst index of the parameter with the specified name, `nil` if no such parameter exists
    public func firstIndex(ofParameterWithName name: String) -> Int? {
        self.firstIndex(of: .namedParameter(name))
    }
    
    
    /// A string representing the "effective path" formed by this array of path components, in a form that allows comparing multiple paths for equality in terms of the HTTP server's routing behaviour
    public var effectivePath: String {
        guard !isEmpty else {
            return "/"
        }
        return self.reduce(into: "") { partialResult, pathComponent in
            partialResult.append("/")
            switch pathComponent {
            case .constant(let value):
                partialResult.append("v[\(value)]")
            case .namedParameter:
                partialResult.append(":")
            case .wildcardSingle(nil):
                partialResult.append("*")
            case .wildcardSingle(.some(let name)):
                partialResult.append("*[\(name)]")
            case .wildcardMultiple(nil):
                partialResult.append("**")
            case .wildcardMultiple(.some(let name)):
                partialResult.append("**[\(name)]")
            }
        }
    }
}


extension String {
    /// The string split into an array of path components
    public var httpPathComponents: [HTTPPathComponent] {
        .init(self)
    }
}


final class HTTPRouter {
    struct Route { // Note that routes are explicitly immutable
        let method: HTTPMethod
        let path: [HTTPPathComponent]
        let expectedCommunicationPattern: Apodini.CommunicationPattern?
        let responder: HTTPResponder
    }
    
    enum RouteRegistrationError: Swift.Error {
        /// The error thrown when a route cannot be added because another route with a conflicting path already exists.
        /// - parameter method: The HTTP method of this route
        /// - parameter conflictingPath: The path of the other route with which the new route conflicts
        /// - parameter newPath: The path of the new route, i.e. the one which couldn't be added
        case conflictingRouteAtSameEffectivePath(HTTPMethod, conflictingPath: [HTTPPathComponent], newPath: [HTTPPathComponent])
    }
    
    private(set) var routes: [HTTPMethod: [Route]] = [:]
    private let logger: Logger
    var isCaseInsensitiveRoutingEnabled = false
    
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    
    var allRoutes: [Route] {
        routes.flatMap(\.value)
    }
    
    
    func add(_ route: Route) throws {
        if routes[route.method] == nil {
            routes[route.method] = []
        }
        if case let effectivePath = route.path.effectivePath,
           let conflictingRoute = routes[route.method]!.first(where: { $0.path.effectivePath == effectivePath })
        {
            throw RouteRegistrationError.conflictingRouteAtSameEffectivePath(route.method, conflictingPath: conflictingRoute.path, newPath: route.path)
        }
        routes[route.method]!.append(route)
        logger.notice("[Router] added \(route.method.rawValue) route at '\(route.path.httpPathString)'")
    }
    
    
    func getRoute(for request: HTTPRequest, populateRequest: Bool) -> Route? {
        if let route = getRoute(for: request, overridingMethod: nil, populateRequest: populateRequest) {
            return route
        } else if request.method == .HEAD {
            // Attempt to forward HEAD requests to GET routes if no HEAD route is available
            return getRoute(for: request, overridingMethod: .GET, populateRequest: populateRequest)
        } else {
            return nil
        }
    }
    
    
    private func getRoute(for request: HTTPRequest, overridingMethod: HTTPMethod?, populateRequest: Bool) -> Route? {
        guard let candidates = routes[request.method] else {
            logger.warning("Unable to find route for \(request) [0]")
            return nil
        }
        
        for route in candidates {
            if let parameters = HTTPPathMatcher.match(
                url: request.url,
                against: route.path,
                allowsCaseInsensitiveMatching: isCaseInsensitiveRoutingEnabled,
                allowsEmptyMultiWildcards: false // NOTE do we want to expose this via a property on the router??
            ) {
                if populateRequest {
                    request.populate(from: route, withParameters: parameters)
                }
                return route
            }
        }
        logger.warning("Unable to find route for \(request) [1]")
        return nil
    }
}
