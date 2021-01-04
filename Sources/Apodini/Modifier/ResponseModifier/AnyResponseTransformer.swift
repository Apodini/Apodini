//
//  AnyResponseTransformer.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import NIO


/// A type erasure for a `ResponseTransformer` or `EncodableResponseTransformer`
public protocol AnyResponseTransformer {
    /// A type erased version of a `ResponseTransformer`'s `Response` type
    var transformedResponseType: Encodable.Type { get }

    
    /// A type erasured version of a `ResponseTransformer`'s or `EncodableResponseTransformer`'s `transform` method
    /// - Parameter response: The input as a type erasured `Action<AnyEncodable>`
    /// - Parameter eventLoop: The `EventLoop` that should be used to retrieve the `Action` of the `Response`
    /// - Returns: The output as a type erasured `EventLoopFuture<Action<AnyEncodable>>`
    func transform(response: Action<AnyEncodable>, on eventLoop: EventLoop) -> EventLoopFuture<Action<AnyEncodable>>
}
