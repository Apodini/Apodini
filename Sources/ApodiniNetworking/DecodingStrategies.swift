import Foundation
import Apodini
import ApodiniExtension


/// Decodes parameters from the `Request`'s query parameters on a name-basis.
public struct LightweightStrategy: EndpointDecodingStrategy {
    public init() {}
    
    public func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, HTTPRequest> {
        LightweightParameterStrategy<Element>(name: parameter.name).typeErased
    }
}


private struct LightweightParameterStrategy<T: Decodable>: ParameterDecodingStrategy {
    let name: String
    
    func decode(from request: HTTPRequest) throws -> T {
        guard let query = try? request.getQueryParam(for: name, as: T.self) else {
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
    
    public init(useNameAsIdentifier: Bool = true) {
        self.useNameAsIdentifier = useNameAsIdentifier
    }
    
    public func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, HTTPRequest> {
        PathParameterStrategy(parameter: parameter, useNameAsIdentifier: useNameAsIdentifier).typeErased
    }
}


private struct PathParameterStrategy<E: Codable>: ParameterDecodingStrategy {
    let parameter: EndpointParameter<E>
    let useNameAsIdentifier: Bool
    
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
    /// a strategy that takes a Vapor `Request` as an ``DecodingStrategy/Input`` by extracting
    /// the request's ``bodyData``.
    func transformedToHTTPRequestBasedStrategy() -> TransformingStrategy<Self, HTTPRequest> {
        self.transformed { (request: HTTPRequest) in
            request.bodyStorage.getFullBodyData() ?? Data()
        }
    }
}


public extension EndpointDecodingStrategy where Input == Data {
    /// Transforms an ``EndpointDecodingStrategy`` with ``EndpointDecodingStrategy/Input`` type `Data` to
    /// a strategy that takes a Vapor `Request` as an ``EndpointDecodingStrategy/Input`` by extracting
    /// the request's ``bodyData``.
    func transformedToHTTPRequestBasedStrategy() -> TransformingEndpointStrategy<Self, HTTPRequest> {
        self.transformed { (request: HTTPRequest) in
            request.bodyStorage.getFullBodyData() ?? Data()
        }
    }
}


public extension BaseDecodingStrategy where Input == Data {
    /// Transforms a ``BaseDecodingStrategy`` with ``BaseDecodingStrategy/Input`` type `Data` to
    /// a strategy that takes a Vapor `Request` as an ``BaseDecodingStrategy/Input`` by extracting
    /// the request's ``bodyData``.
    func transformedToHTTPRequestBasedStrategy() -> TransformingBaseStrategy<Self, HTTPRequest> {
        self.transformed { (request: HTTPRequest) in
            request.bodyStorage.getFullBodyData() ?? Data()
        }
    }
}
