import Foundation
import Apodini
import ApodiniExtension


// TODO does this really belong in here?

/// Decodes parameters from the `Request`'s query parameters on a name-basis.
public struct LightweightStrategy: EndpointDecodingStrategy {
    public init() {}
    
    public func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, LKHTTPRequest> {
        LightweightParameterStrategy<Element>(name: parameter.name).typeErased
    }
}


private struct LightweightParameterStrategy<T: Decodable>: ParameterDecodingStrategy {
    let name: String
    
    func decode(from request: LKHTTPRequest) throws -> T {
        //guard let query = request.query[E.self, at: name] else {
        guard let query = try? request.getQueryParam(for: name, as: T.self) else {
            // the query parameter doesn't exists
            //fatalError()
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
    
    public func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, LKHTTPRequest> {
        PathParameterStrategy(parameter: parameter, useNameAsIdentifier: useNameAsIdentifier).typeErased
    }
}


private struct PathParameterStrategy<E: Codable>: ParameterDecodingStrategy {
    let parameter: EndpointParameter<E>
    let useNameAsIdentifier: Bool
    
    func decode(from request: LKHTTPRequest) throws -> E {
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
            throw ApodiniError(type: .badInput, reason: """
                                                        Encountered illegal input for path parameter \(parameter.name).
                                                        \(Element.self) can't be initialized from \(stringParameter).
                                                        """)
        }
        
        return value
    }
}



// TODO can we get rid of the "transformedToVapor..." stuff below?


public extension DecodingStrategy where Input == Data {
    /// Transforms a ``DecodingStrategy`` with ``DecodingStrategy/Input`` type `Data` to
    /// a strategy that takes a Vapor `Request` as an ``DecodingStrategy/Input`` by extracting
    /// the request's ``bodyData``.
    func transformedToVaporRequestBasedStrategy() -> TransformingStrategy<Self, LKHTTPRequest> {
        self.transformed { (request: LKHTTPRequest) in
            request.bodyStorage.getFullBodyData() ?? Data()
        }
    }
}


public extension EndpointDecodingStrategy where Input == Data {
    /// Transforms an ``EndpointDecodingStrategy`` with ``EndpointDecodingStrategy/Input`` type `Data` to
    /// a strategy that takes a Vapor `Request` as an ``EndpointDecodingStrategy/Input`` by extracting
    /// the request's ``bodyData``.
    func transformedToVaporRequestBasedStrategy() -> TransformingEndpointStrategy<Self, LKHTTPRequest> {
        self.transformed { (request: LKHTTPRequest) in
            request.bodyStorage.getFullBodyData() ?? Data()
        }
    }
}


public extension BaseDecodingStrategy where Input == Data {
    /// Transforms a ``BaseDecodingStrategy`` with ``BaseDecodingStrategy/Input`` type `Data` to
    /// a strategy that takes a Vapor `Request` as an ``BaseDecodingStrategy/Input`` by extracting
    /// the request's ``bodyData``.
    func transformedToVaporRequestBasedStrategy() -> TransformingBaseStrategy<Self, LKHTTPRequest> {
        self.transformed { (request: LKHTTPRequest) in
            request.bodyStorage.getFullBodyData() ?? Data()
        }
    }
}


//public extension Vapor.Request {
//    /// Extracts the readable part of the request's `body` and returns it as a `Data` object. If no data is found, an empty
//    /// `Data` object is returned.
//    var bodyData: Data {
//        if let buffer = self.body.data {
//            return buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes) ?? Data()
//        } else {
//            return Data()
//        }
//    }
//}

//extension LKHTTPRequest {
//    /// Extracts the readable part of the request's `body` and returns it as a `Data` object. If no data is found, an empty
//    /// `Data` object is returned.
//    public var bodyData: Data {
//        // TODO does this move the reader? do we want the reader to be moved? (no). what if the reader is not at the start bc someone already read a bit? do we want the full body? (yes) <-- TODO!!!!
//        return body.getData(at: body.readerIndex, length: body.readableBytes) ?? Data()
//    }
//}
