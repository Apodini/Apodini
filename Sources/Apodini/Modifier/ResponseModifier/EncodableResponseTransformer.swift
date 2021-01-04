//
//  EncodableResponseTransformer.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import NIO


/// A `EncodableResponseTransformer` transforms a `response` of the type `Response` to a instance conforming to `TransformedResponse`.
/// An `EncodableResponseTransformer` is able to map `Encodable` types without the need to deal with an `Action` type  of the previous `Handler` or `ResponseTransformer`.
/// It only maps in the `.send`,  `.finish` and `.automatic` cases.
/// If the previous Handler or ResponseTransformer returned an `Action.end` or `Action.nothing` it is not called and will not map anything.
/// Both types (`Response` and `TransformedResponse`) have to conform to `Encodable`
public protocol EncodableResponseTransformer: AnyResponseTransformer {
    /// The type that should be transformed
    associatedtype Response: Encodable
    /// The type the `Response`  should be transformed to
    associatedtype TransformedResponse: Encodable
    
    
    /// Transforms a `response` of the type `Response` to a instance conforming to `TransformedResponse`.
    /// Both types (`Response` and `TransformedResponse`) have to conform to `Encodable`.
    /// - Parameter response: The response that should be transformed
    func transform(response: Self.Response) -> Self.TransformedResponse
}


extension EncodableResponseTransformer {
    /// A type erased version of a `EncodableResponseTransformer`'s `Response` type
    public var transformedResponseType: Encodable.Type {
        Self.TransformedResponse.ResponseContent.self
    }
    
    
    /// A type erasured version of a `EncodableResponseTransformer`'s `transform(response: Self.Response) -> TransformedResponse` method
    /// - Parameter response: The input as a type erasured `Action<AnyEncodable>`
    /// - Parameter eventLoop: The `EventLoop` that should be used to retrieve the `Action` of the `Response`
    /// - Returns: The output as a type erasured `EventLoopFuture<Action<AnyEncodable>>`
    public func transform(response: Action<AnyEncodable>, on eventLoop: EventLoop) -> EventLoopFuture<Action<AnyEncodable>> {
        guard let typedResponse = response.typed(Self.Response.self) else {
            fatalError("Could not cast the `Action<AnyEncodable>` passed to the `ResponseTransformer` to the expected \(Action<Self.Response>.self) type")
        }
        
        let transformed: Action<TransformedResponse.ResponseContent>
        switch typedResponse {
        case .nothing:
            transformed = .nothing
        case let .send(element):
            transformed = .send(transform(response: element))
        case let .final(element):
            transformed = .final(transform(response: element))
        case let .automatic(element):
            transformed = .automatic(transform(response: element))
        case .end:
            transformed = .end
        }
        
        return transformed
            .action(on: eventLoop)
            .map { typedAction in
                typedAction.typeErasured
            }
    }
}


extension Handler {
    /// A `response` modifier can be used to transform the output of a `Handler`'s response to a different type using a `EncodableResponseTransformer`
    /// - Parameter responseTransformer: The `EncodableResponseTransformer` used to transform the response of a `Handler`
    /// - Returns: The modified `Handler` with a new `Response` type
    public func response<T: EncodableResponseTransformer>(
        _ responseTransformer: @escaping @autoclosure () -> (T)
    ) -> EncodableResponseModifier<Self, T> where Self.Response.ResponseContent == T.Response {
        EncodableResponseModifier(self, responseTransformer: responseTransformer)
    }
}
