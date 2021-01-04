//
//  ResponseTransformer.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import NIO


/// A `ResponseTransformer` transforms a `response` of the type `Response` to a instance conforming to `TransformedResponse`
public protocol SomeResponseTransformer: AnyResponseTransformer {
    /// The type that should be transformed
    associatedtype Response: Encodable
    /// The type the `Response`  should be transformed to
    associatedtype TransformedResponse
}

/// A `ResponseTransformer` transforms a `response` of the type `Response` to a instance conforming to `TransformedResponse`
public protocol ResponseTransformer: AnyResponseTransformer {
    /// The type that should be transformed
    associatedtype Response: Encodable
    /// The type the `Response`  should be transformed to
    associatedtype TransformedResponse: Apodini.Response
    
    
    /// Transforms a `response` of the type `Action<Self.Response>` to a instance conforming to `TransformedResponse`
    /// - Parameter response: The response that should be transformed
    func transform(response: Action<Self.Response>) -> Self.TransformedResponse
}


extension ResponseTransformer {
    /// A type erased version of a `ResponseTransformer`'s `Response` type
    public var transformedResponseType: Encodable.Type {
        Self.TransformedResponse.ResponseContent.self
    }
    
    
    /// A type erasured version of a `ResponseTransformer`'s `transform(response: Action<Self.Response>) -> Self.TransformedResponse` method
    /// - Parameter response: The input as a type erasured `Action<AnyEncodable>`
    /// - Parameter eventLoop: The `EventLoop` that should be used to retrieve the `Action` of the `Response`
    /// - Returns: The output as a type erasured `EventLoopFuture<Action<AnyEncodable>>`
    public func transform(response: Action<AnyEncodable>, on eventLoop: EventLoop) -> EventLoopFuture<Action<AnyEncodable>> {
        guard let typedResponse = response.typed(Self.Response.self) else {
            fatalError("Could not cast the `Action<AnyEncodable>` passed to the `ResponseTransformer` to the expected \(Action<Self.Response>.self) type")
        }
        
        return self.transform(response: typedResponse)
            .action(on: eventLoop)
            .map { typedAction in
                typedAction.typeErasured
            }
    }
}


extension Handler {
    /// A `response` modifier can be used to transform the output of a `Handler`'s response to a different type using a `ResponseTransformer`
    /// - Parameter responseTransformer: The `ResponseTransformer` used to transform the response of a `Handler`
    /// - Returns: The modified `Handler` with a new `Response` type
    public func response<T: ResponseTransformer>(
        _ responseTransformer: @escaping @autoclosure () -> (T)
    ) -> ResponseModifier<Self, T> where Self.Response.ResponseContent == T.Response {
        ResponseModifier(self, responseTransformer: responseTransformer)
    }
}
