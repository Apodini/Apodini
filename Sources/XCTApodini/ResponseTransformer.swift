//
//  ResponseTransformer.swift
//  
//
//  Created by Max Obermeier on 06.06.21.
//


#if DEBUG || RELEASE_TESTING
@testable import Apodini
import ApodiniUtils

// MARK: Guarded Handler
public extension Handler {
    /// Transforms the handler's result using the given `transformer`, just as `.response()` does on non-mocked `Handler`s.
    /// - Note: This is only to be used when manually constructing an `Endpoint`
    func transformed<T: ResponseTransformer>(_ transformer: T) -> ResponseTransformingHandler<Self, T> {
        ResponseTransformingHandler(transformed: Delegate(self), transformer: Delegate(transformer))
    }
}

public extension ResponseTransformer {
    /// A type erased version of a `ResponseTransformer`'s `Response` type
    var transformedResponseContent: Encodable.Type {
        Self.Content.self
    }
    
    
    /// A type erasured version of a `ResponseTransformer`'s `transform(response: Self.ResponseTransformable) -> TransformedContent` method
    /// - Parameter response: The input as a type erasured `Response<AnyEncodable>`
    /// - Parameter eventLoop: The `EventLoop` that should be used to retrieve the `Response` of the `ResponseTransformable`
    /// - Returns: The output as a type erasured `EventLoopFuture<Response<AnyEncodable>>`
    func transform(response: Response<AnyEncodable>, on eventLoop: EventLoop) -> EventLoopFuture<Response<AnyEncodable>> {
        guard let typedInputResponse = response.typed(Self.InputContent.self) else {
            fatalError("Could not cast the `Response<AnyEncodable>` passed to the `ResponseTransformer` to the expected \(Response<Self.Content>.self) type")
        }
        
        return typedInputResponse
            .map(transform(content:))
            .transformToResponse(on: eventLoop)
            .map { typedResponse in
                typedResponse.typeErasured
            }
    }
}
#endif
