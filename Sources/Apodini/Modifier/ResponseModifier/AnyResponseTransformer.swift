//
//  AnyResponseTransformer.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import NIO


/// A type erasure for a  `ResponseTransformer`
public protocol AnyResponseTransformer {
    /// A type erased version of a `ResponseTransformer`'s `Content` type
    var transformedResponseContent: Encodable.Type { get }

    
    /// A type erasured version of a `ResponseTransformer`'s `transform` method
    /// - Parameter response: The input as a type erasured `Response<AnyEncodable>`
    /// - Parameter eventLoop: The `EventLoop` that should be used to retrieve the `Response` of the `ResponseTransformable`
    /// - Returns: The output as a type erasured `EventLoopFuture<Response<AnyEncodable>>`
    func transform(response: Response<AnyEncodable>, on eventLoop: EventLoop) -> EventLoopFuture<Response<AnyEncodable>>
}
