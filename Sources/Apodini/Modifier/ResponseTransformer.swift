//
//  ResponseTransformer.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import NIO
import ApodiniUtils


/// A `ResponseTransformer` transforms a `response` of the type `InputContent` to a instance conforming to `Content`.
/// An `ResponseTransformer` is able to map `Encodable` types without the need to deal with an `Response` type  of the previous `Handler`.
/// It only maps in the `.send`,  `.finish` and `.automatic` cases.
/// If the previous Handler or ResponseTransformer returned an `Response.end` or `Response.nothing` it is not called and will not map anything.
/// Both types (`InputContent` and `Content`) have to conform to `Encodable`
public protocol ResponseTransformer {
    /// The type that should be transformed
    associatedtype InputContent: Encodable
    /// The type the `ResponseTransformable`  should be transformed to
    associatedtype Content: Encodable
    
    
    /// Transforms a `response` of the type `ResponseTransformable` to a instance conforming to `TransformedContent`.
    /// Both types (`ResponseTransformable` and `TransformedContent`) have to conform to `Encodable`.
    /// - Parameter response: The response that should be transformed
    func transform(content: Self.InputContent) -> Self.Content
}

internal struct ResponseTransformingHandler<D, T>: Handler where D: Handler, T: ResponseTransformer, D.Response.BodyContent == T.InputContent {
    let transformed: Delegate<D>
    let transformer: Delegate<T>
    
    @Environment(\.connection) var connection
    
    func handle() throws -> EventLoopFuture<Response<T.Content>> {
        try transformed().handle().transformToResponse(on: connection.eventLoop).flatMapThrowing { responseToTransform in
            try responseToTransform.map { content in
                try transformer().transform(content: content)
            }
        }
    }
}

public struct ResponseTransformingHandlerInitializer<T: ResponseTransformer>: DelegatingHandlerInitializer {
    public typealias Response = Apodini.Response<T.Content>
    
    let transformer: T
    
    public func instance<D>(for delegate: D) throws -> SomeHandler<Response> where D: Handler {
        if let transformingHandler =
            (TransformerCandidate(
                transformer: transformer,
                delegate: delegate) as? Transformable)?() as? SomeHandler<Response> {
            return transformingHandler
        }
        
        fatalError("Cannot use response transformer \(transformer) with handler of type \(D.self) because content types do not match.")
    }
}

private struct TransformerCandidate<Transformer: ResponseTransformer, Delegate: Handler> {
    let transformer: Transformer
    let delegate: Delegate
}

extension TransformerCandidate: Transformable where Transformer.InputContent == Delegate.Response.BodyContent {
    func callAsFunction() -> Any {
        SomeHandler<Response<Transformer.Content>>(ResponseTransformingHandler<Delegate, Transformer>(
                                                    transformed: Apodini.Delegate(delegate),
                                                    transformer: Apodini.Delegate(transformer)))
    }
}

private protocol Transformable {
    func callAsFunction() -> Any
}

extension Handler {
    /// A `response` modifier can be used to transform the output of a `Handler`'s response to a different type using a `ResponseTransformer`
    /// - Parameter responseTransformer: The `ResponseTransformer` used to transform the response of a `Handler`
    /// - Returns: The modified `Handler` with a new `ResponseTransformable` type
    public func response<T: ResponseTransformer>(
        _ responseTransformer: T
    ) -> DelegationModifier<Self, ResponseTransformingHandlerInitializer<T>> where Self.Response.BodyContent == T.InputContent {
        self.delegated(by: ResponseTransformingHandlerInitializer(transformer: responseTransformer))
    }
}
