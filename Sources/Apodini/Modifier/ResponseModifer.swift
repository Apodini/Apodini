//
//  ResponseModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor
import Runtime


/// A type erasure for a `ResponseTransformer`
public protocol AnyResponseTransformer {
    /// A type erased version of a `ResponseTransformer`'s `Response` type
    var transformedResponseType: ResponseEncodable.Type { get }
    
    
    /// A type erasured version of a `ResponseTransformer`'s `transform(response: Self.Response) -> TransformedResponse` method
    /// - Parameter response: The input as a type erasured `ResponseEncodable`
    /// - Returns: The output as a type erasured `ResponseEncodable`
    func transform(response: ResponseEncodable) -> ResponseEncodable
}


/// A `ResponseTransformer` transforms a `response` of the type `Response` to a instance conforming to `TransformedResponse`
public protocol ResponseTransformer: AnyResponseTransformer {
    /// The type that should be transformed
    associatedtype Response
    /// The type the `Response`  should be transformed to
    associatedtype TransformedResponse: ResponseEncodable
    
    
    /// Transforms a `response` of the type `Response` to a instance conforming to `TransformedResponse`
    /// - Parameter response: The response that should be transformed
    func transform(response: Self.Response) -> TransformedResponse
}


extension ResponseTransformer {
    /// A type erased version of a `ResponseTransformer`'s `Response` type
    public var transformedResponseType: ResponseEncodable.Type {
        Self.TransformedResponse.self
    }
    
    
    /// A type erasured version of a `ResponseTransformer`'s `transform(response: Self.Response) -> TransformedResponse` method
    /// - Parameter response: The input as a type erasured `ResponseEncodable`
    /// - Returns: The output as a type erasured `ResponseEncodable`
    public func transform(response: ResponseEncodable) -> ResponseEncodable {
        guard let response = response as? Self.Response else {
            fatalError("Coult not cast the `ResponseEncodable` passed to the `AnyResponseTransformer` to the expected \(Response.self) type")
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


/// A `ResponseModifier` can be used to transfrom the output of `Component`'s response to a differnt type using a `ResponseTransformer`
public struct ResponseModifier<C: Component, T: ResponseTransformer>: Modifier where T.Response == C.Response {
    public typealias Response = T.TransformedResponse
    
    let component: C
    let responseTransformer: () -> (T)
    
    
    init(_ component: C, responseTransformer: @escaping () -> (T)) {
        precondition(((try? typeInfo(of: T.self).kind) ?? .none) == .struct, "ResponseTransformer \((try? typeInfo(of: T.self).name) ?? "unknown") must be a struct")
        
        self.component = component
        self.responseTransformer = responseTransformer
    }
    
    
    /// A `Modifier`'s handle method should never be called!
    public func handle() -> Self.Response {
        fatalError("A Modifier's handle method should never be called!")
    }
}


extension ResponseModifier: Visitable {
    func visit(_ visitor: SynaxTreeVisitor) {
        visitor.addContext(ResponseContextKey.self, value: [responseTransformer], scope: .nextComponent)
        component.visit(visitor)
    }
}


extension Component {
    /// A `response` modifier can be used to transfrom the output of `Component`'s response to a differnt type using a `ResponseTransformer`
    /// - Parameter responseTransformer: The `ResponseTransformer` used to transform the response of a `Component`
    /// - Returns: The modified `Component` with a new `Response` type
    public func response<T: ResponseTransformer>(
        _ responseTransformer: @escaping @autoclosure () -> (T)
    ) -> ResponseModifier<Self, T> where Self.Response == T.Response {
        ResponseModifier(self, responseTransformer: responseTransformer)
    }
}
