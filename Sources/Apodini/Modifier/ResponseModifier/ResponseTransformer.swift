//
//  ResponseTransformer.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import NIO


/// A `ResponseTransformer` transforms a `response` of the type `InputContent` to a instance conforming to `Content`.
/// An `ResponseTransformer` is able to map `Encodable` types without the need to deal with an `Response` type  of the previous `Handler`.
/// It only maps in the `.send`,  `.finish` and `.automatic` cases.
/// If the previous Handler or ResponseTransformer returned an `Response.end` or `Response.nothing` it is not called and will not map anything.
/// Both types (`InputContent` and `Content`) have to conform to `Encodable`
public protocol ResponseTransformer: AnyResponseTransformer {
    /// The type that should be transformed
    associatedtype InputContent: Encodable
    /// The type the `ResponseTransformable`  should be transformed to
    associatedtype Content: Encodable
    
    
    /// Transforms a `response` of the type `ResponseTransformable` to a instance conforming to `TransformedContent`.
    /// Both types (`ResponseTransformable` and `TransformedContent`) have to conform to `Encodable`.
    /// - Parameter response: The response that should be transformed
    func transform(content: Self.InputContent) -> Self.Content
}


extension ResponseTransformer {
    /// A type erased version of a `ResponseTransformer`'s `Response` type
    public var transformedResponseContent: Encodable.Type {
        Self.Content.self
    }
    
    
    /// A type erasured version of a `ResponseTransformer`'s `transform(response: Self.ResponseTransformable) -> TransformedContent` method
    /// - Parameter response: The input as a type erasured `Response<AnyEncodable>`
    /// - Parameter eventLoop: The `EventLoop` that should be used to retrieve the `Response` of the `ResponseTransformable`
    /// - Returns: The output as a type erasured `EventLoopFuture<Response<AnyEncodable>>`
    public func transform(response: Response<AnyEncodable>, on eventLoop: EventLoop) -> EventLoopFuture<Response<AnyEncodable>> {
        guard let typedInputReponse = response.typed(Self.InputContent.self) else {
            fatalError("Could not cast the `Response<AnyEncodable>` passed to the `ResponseTransformer` to the expected \(Response<Self.Content>.self) type")
        }
        
        return typedInputReponse
            .map(transform(content:))
            .transformToResponse(on: eventLoop)
            .map { typedResponse in
                typedResponse.typeErasured
            }
    }
}


extension Handler {
    /// A `response` modifier can be used to transform the output of a `Handler`'s response to a different type using a `ResponseTransformer`
    /// - Parameter responseTransformer: The `ResponseTransformer` used to transform the response of a `Handler`
    /// - Returns: The modified `Handler` with a new `ResponseTransformable` type
    public func response<T: ResponseTransformer>(
        _ responseTransformer: @escaping @autoclosure () -> (T)
    ) -> ResponseModifier<Self, T> where Self.Response.Content == T.InputContent {
        ResponseModifier(self, responseTransformer: responseTransformer)
    }
}
