//
//  ResponseModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
@_implementationOnly import Runtime


/// A type erasure for a `ResponseTransformer`
public protocol AnyResponseTransformer {
    /// A type erased version of a `ResponseTransformer`'s `Response` type
    var transformedResponseType: Encodable.Type { get }

    
    /// A type erasured version of a `ResponseTransformer`'s `transform(response: Self.Response) -> TransformedResponse` method
    /// - Parameter response: The input as a type erasured `ResponseEncodable`
    /// - Returns: The output as a type erasured `ResponseEncodable`
    func transform(response: Encodable) -> Encodable
}


/// A `ResponseTransformer` transforms a `response` of the type `Response` to a instance conforming to `TransformedResponse`
public protocol ResponseTransformer: AnyResponseTransformer {
    /// The type that should be transformed
    associatedtype Response
    /// The type the `Response`  should be transformed to
    associatedtype TransformedResponse: Encodable
    
    
    /// Transforms a `response` of the type `Response` to a instance conforming to `TransformedResponse`
    /// - Parameter response: The response that should be transformed
    func transform(response: Self.Response) -> TransformedResponse
}


extension ResponseTransformer {
    /// A type erased version of a `ResponseTransformer`'s `Response` type
    public var transformedResponseType: Encodable.Type {
        Self.TransformedResponse.self
    }
    
    
    /// A type erasured version of a `ResponseTransformer`'s `transform(response: Self.Response) -> TransformedResponse` method
    /// - Parameter response: The input as a type erasured `Encodable`
    /// - Returns: The output as a type erasured `Encodable`
    public func transform(response: Encodable) -> Encodable {
        guard let response = response as? Self.Response else {
            fatalError("Could not cast the `Encodable` passed to the `AnyResponseTransformer` to the expected \(Response.self) type")
        }
        return self.transform(response: response)
    }
}


struct ResponseContextKey: ContextKey {
    static var defaultValue: [() -> (AnyResponseTransformer)] = []
    
    static func reduce(value: inout [() -> (AnyResponseTransformer)], nextValue: () -> [() -> (AnyResponseTransformer)]) {
        value.append(contentsOf: nextValue())
    }
}


/// A `ResponseModifier` can be used to transform the output of `Component`'s response to a different type using a `ResponseTransformer`
public struct ResponseModifier<H: Handler, T: ResponseTransformer>: HandlerModifier where H.Response == T.Response {
    public typealias Response = T.TransformedResponse
    
    public let component: H
    let responseTransformer: () -> (T)
    
    
    init(_ component: H, responseTransformer: @escaping () -> (T)) {
        assertTypeIsStruct(T.self, messagePrefix: "ResponseTransformer")
        self.component = component
        self.responseTransformer = responseTransformer
    }
}


extension ResponseModifier: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(ResponseContextKey.self, value: [responseTransformer], scope: .nextHandler)
        component.accept(visitor)
    }
}


extension Handler {
    /// A `response` modifier can be used to transform the output of a `Handler`'s response to a different type using a `ResponseTransformer`
    /// - Parameter responseTransformer: The `ResponseTransformer` used to transform the response of a `Handler`
    /// - Returns: The modified `Handler` with a new `Response` type
    public func response<T: ResponseTransformer>(
        _ responseTransformer: @escaping @autoclosure () -> (T)
    ) -> ResponseModifier<Self, T> where Self.Response == T.Response {
        ResponseModifier(self, responseTransformer: responseTransformer)
    }
}
