//
//  DecodingStrategies.swift
//  
//
//  Created by Max Obermeier on 27.06.21.
//

import Foundation
import Vapor
import Apodini
import ApodiniExtension

public struct LightweightStrategy: EndpointDecodingStrategy {
    public init() {}
    
    public func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Vapor.Request> {
        LightweightParameterStrategy<Element>(name: parameter.name).typeErased
    }
}

private struct LightweightParameterStrategy<E: Decodable>: ParameterDecodingStrategy {
    let name: String
    
    func decode(from request: Vapor.Request) throws -> E {
        guard let query = request.query[E.self, at: name] else {
            throw DecodingError.keyNotFound(
                name,
                DecodingError.Context(codingPath: [name],
                                      debugDescription: "No query parameter with name \(name) present in request \(request.description)",
                                      underlyingError: nil)) // the query parameter doesn't exists
        }
        return query
    }
}

public struct PathStrategy: EndpointDecodingStrategy {
    public init() {}
    
    public func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Vapor.Request> {
        PathParameterStrategy(parameter: parameter).typeErased
    }
}


private struct PathParameterStrategy<E: Codable>: ParameterDecodingStrategy {
    let parameter: EndpointParameter<E>
    
    func decode(from request: Vapor.Request) throws -> E {
        guard let stringParameter = request.parameters.get(parameter.name) else {
            throw DecodingError.keyNotFound(
                parameter.name,
                DecodingError.Context(
                    codingPath: [parameter.name],
                    debugDescription: "No path parameter with name \(parameter.name) present in request \(request.description)",
                    underlyingError: nil
                )) // the path parameter didn't exist on that request
        }
        
        guard let value = parameter.initLosslessStringConvertibleParameterValue(from: stringParameter) else {
            throw ApodiniError(type: .badInput, reason: """
                                                        Encountered illegal input for path parameter \(parameter.name).
                                                        \(Element.self) can't be initialized from \(stringParameter).
                                                        """)
        }
        
        return value
    }
}


public extension DecodingStrategy where Input == Data {
    /// Transforms a ``DecodingStrategy`` with ``DecodingStrategy/Input`` type `Data` to
    /// a strategy that takes a Vapor `Request` as an ``DecodingStrategy/Input`` by extracting
    /// the request's ``bodyData``.
    func transformedToVaporRequestBasedStrategy() -> TransformingStrategy<Self, Vapor.Request> {
        self.transformed { (request: Vapor.Request) in
            request.bodyData
        }
    }
}

public extension EndpointDecodingStrategy where Input == Data {
    /// Transforms an ``EndpointDecodingStrategy`` with ``EndpointDecodingStrategy/Input`` type `Data` to
    /// a strategy that takes a Vapor `Request` as an ``EndpointDecodingStrategy/Input`` by extracting
    /// the request's ``bodyData``.
    func transformedToVaporRequestBasedStrategy() -> TransformingEndpointStrategy<Self, Vapor.Request> {
        self.transformed { (request: Vapor.Request) in
            request.bodyData
        }
    }
}

public extension BaseDecodingStrategy where Input == Data {
    /// Transforms a ``BaseDecodingStrategy`` with ``BaseDecodingStrategy/Input`` type `Data` to
    /// a strategy that takes a Vapor `Request` as an ``BaseDecodingStrategy/Input`` by extracting
    /// the request's ``bodyData``.
    func transformedToVaporRequestBasedStrategy() -> TransformingBaseStrategy<Self, Vapor.Request> {
        self.transformed { (request: Vapor.Request) in
            request.bodyData
        }
    }
}

public extension Vapor.Request {
    /// Extracts the readable part of the request's `body` and returns it as a `Data` object. If no data is found, an empty
    /// `Data` object is returned.
    var bodyData: Data {
        if let buffer = self.body.data {
            return buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes) ?? Data()
        } else {
            return Data()
        }
    }
}
