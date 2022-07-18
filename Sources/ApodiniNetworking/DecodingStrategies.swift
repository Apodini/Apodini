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


/// Decodes parameters from the `Request`'s query parameters on a name-basis.
public struct LightweightStrategy: EndpointDecodingStrategy {
    let dateDecodingStrategy: DateDecodingStrategy
    
    /// - parameter dateDecodingStrategy: How `Foundation.Date` objects should be decoded
    public init(dateDecodingStrategy: DateDecodingStrategy = .default) {
        self.dateDecodingStrategy = dateDecodingStrategy
    }
    
    public func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, HTTPRequest> {
        LightweightParameterStrategy<Element>(name: parameter.name, dateDecodingStrategy: dateDecodingStrategy).typeErased
    }
}


private struct LightweightParameterStrategy<T: Decodable>: ParameterDecodingStrategy {
    let name: String
    let dateDecodingStrategy: DateDecodingStrategy
    
    func decode(from request: HTTPRequest) throws -> T {
        guard let query = try? request.getQueryParam(for: name, as: T.self, dateDecodingStrategy: dateDecodingStrategy) else {
            // the query parameter doesn't exist
            throw DecodingError.keyNotFound(
                name,
                DecodingError.Context(
                    codingPath: [name],
                    debugDescription: "No query parameter with name '\(name)' of type '\(T.self)' present in request \(request.description)",
                    underlyingError: nil
                )
            )
        }
        return query
    }
}


/// Decodes parameters from the `Request`'s path parameters matching either on a name- or id-basis.
public struct PathStrategy: EndpointDecodingStrategy {
    let useNameAsIdentifier: Bool
    let dateDecodingStrategy: DateDecodingStrategy
    
    public init(useNameAsIdentifier: Bool = true, dateDecodingStrategy: DateDecodingStrategy = .default) {
        self.useNameAsIdentifier = useNameAsIdentifier
        self.dateDecodingStrategy = dateDecodingStrategy
    }
    
    public func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, HTTPRequest> {
        PathParameterStrategy(parameter: parameter, useNameAsIdentifier: useNameAsIdentifier, dateDecodingStrategy: dateDecodingStrategy).typeErased
    }
}


private struct PathParameterStrategy<E: Codable>: ParameterDecodingStrategy {
    let parameter: EndpointParameter<E>
    let useNameAsIdentifier: Bool
    let dateDecodingStrategy: DateDecodingStrategy
    
    func decode(from request: HTTPRequest) throws -> E {
        guard let stringParameter = request.getParameterRawValue(useNameAsIdentifier ? parameter.name : parameter.id.uuidString) else {
            throw DecodingError.keyNotFound(
                parameter.name,
                DecodingError.Context(
                    codingPath: [parameter.name],
                    debugDescription: "No path parameter with name \(parameter.name) present in request \(request.description)",
                    underlyingError: nil
                )) // the path parameter didn't exist on that request
        }
        
        if E.self == Date.self {
            return try dateDecodingStrategy.decodeDate(from: stringParameter) as! E
        }
        
        guard let value = parameter.initLosslessStringConvertibleParameterValue(from: stringParameter) else {
            throw ApodiniError(
                type: .badInput,
                reason: """
                    Encountered illegal input for path parameter \(parameter.name).
                    \(Element.self) can't be initialized from \(stringParameter).
                    """
            )
        }
        return value
    }
}


public extension DecodingStrategy where Input == Data {
    /// Transforms a ``DecodingStrategy`` with ``DecodingStrategy/Input`` type `Data` to
    /// a strategy that takes an `HTTPRequest` by extracting
    /// the request's ``bodyData``.
    func transformedToHTTPRequestBasedStrategy() -> TransformingStrategy<Self, HTTPRequest> {
        self.transformed { (request: HTTPRequest) in
            request.bodyStorage.getFullBodyData() ?? Data()
        }
    }
}


public extension EndpointDecodingStrategy where Input == Data {
    /// Transforms an ``EndpointDecodingStrategy`` with ``EndpointDecodingStrategy/Input`` type `Data` to
    /// a strategy that takes an `HTTPRequest` by extracting
    /// the request's ``bodyData``.
    func transformedToHTTPRequestBasedStrategy() -> TransformingEndpointStrategy<Self, HTTPRequest> {
        self.transformed { (request: HTTPRequest) in
            request.bodyStorage.getFullBodyData() ?? Data()
        }
    }
}


public extension BaseDecodingStrategy where Input == Data {
    /// Transforms a ``BaseDecodingStrategy`` with ``BaseDecodingStrategy/Input`` type `Data` to
    /// a strategy that takes an `HTTPRequest` by extracting
    /// the request's ``bodyData``.
    func transformedToHTTPRequestBasedStrategy() -> TransformingBaseStrategy<Self, HTTPRequest> {
        self.transformed { (request: HTTPRequest) in
            request.bodyStorage.getFullBodyData() ?? Data()
        }
    }
}
