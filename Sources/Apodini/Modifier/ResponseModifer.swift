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
        visitor.addContext(ResponseContextKey.self, value: [responseTransformer], scope: .nextComponent)
        component.accept(visitor)
    }
}


/// An `ActionResponseModifier` can be used to transform the output of `Component`'s response,
/// which is wrapped inside an `Action`, to a different type using a `ResponseTransformer`.
/// The output of the `ResponseTransformer` again will be wrapped in the identical type of `Action`.
/// To be able to not only transform the type of the wrapped value, but also the type of `Action`
/// use a normal `ResponseModifier` (which will then reveive the complete `Action` and not only the wrapped value).
public struct ActionResponseModifier<H: Handler, T: ResponseTransformer>: Modifier where Action<T.Response> == H.Response {
    public typealias Response = Action<T.TransformedResponse>

    public let component: H
    let responseTransformer: () -> (T)


    init(_ component: H, responseTransformer: @escaping () -> (T)) {
        precondition(((try? typeInfo(of: T.self).kind) ?? .none) == .struct, "ResponseTransformer \((try? typeInfo(of: T.self).name) ?? "unknown") must be a struct")

        self.component = component
        self.responseTransformer = responseTransformer
    }


    /// A `Modifier`'s handle method should never be called!
    public func handle() -> Self.Response {
        fatalError("A Modifier's handle method should never be called!")
    }
}


extension ActionResponseModifier: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(ResponseContextKey.self, value: [responseTransformer], scope: .nextComponent)
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
        if Self.Response.self is ApodiniEncodable.Type {
            preconditionFailure("Actions cannot be transformed directly. Use a transformer on the type that is wrapped by the Action instead.")
        }
        return ResponseModifier(self, responseTransformer: responseTransformer)
    }

    /// A `response` modifier can be used to transform the output of `Handler`'s response to a different type using a `ResponseTransformer`
    /// - Parameter responseTransformer: The `ResponseTransformer` used to transform the response of a `Handler`
    /// - Returns: The modified `Handler` with a new `Response` type
    public func response<T: ResponseTransformer>(
        _ responseTransformer: @escaping @autoclosure () -> (T)
    ) -> ActionResponseModifier<Self, T> where Self.Response == Action<T.Response> {
        ActionResponseModifier(self, responseTransformer: responseTransformer)
    }
}
