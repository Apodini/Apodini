//
// Created by Andreas Bauer on 01.01.21.
//

import Foundation
import NIO


/// A common `ResponseTransformable` type that all types returned from a `handle()` method in a `Handler` have to conform to.
///
/// Common types like `String`, `Int` (including variations like `UInt64`) , `Double`, `Float`,`Bool`, and `UUID`,  and the corresponding `EventLoopFuture`wrappers all conform to `ResponseTransformable` out of the box.
/// Collection types (`Array`, `Dictionary`, `Set`) also conform to `ResponseTransformable` if the elements conform to `Encodable`.
/// Types that conform to `Encodable` can conform to `ResponseTransformable` without the need to implement any additional methods.
public protocol ResponseTransformable {
    /// The `Encodable` type that is returned from a `handle()` method in a `Handler`.
    /// The type can be wrapped by an `EventLoopFuture` or an `Response`.
    associatedtype Content: Encodable
    
    /// Transforms an `ResponseTransformable` into an `Response` to be processed by the Apodini
    /// - Parameter eventLoop: The `EventLoop` that should be used to transform the `ResponseTransformable` to an `Response` if needed
    func transformToResponse(on eventLoop: EventLoop) -> EventLoopFuture<Response<Content>>
}


// MARK: ResponseTransformable for Generic Encodable Types
extension Encodable {
    /// Default Implementation for types conforming to `ResponseTransformable`
    /// 
    /// The `Encodable` type that is returned from a `handle()` method in a `Handler`.
    /// The type can be wrapped by an `EventLoopFuture` or an `Response`.
    public typealias Content = Self
    
    /// Default Implementation for types conforming to `ResponseTransformable`
    ///
    /// Transforms an `ResponseTransformable` into an `Response` to be processed by the Apodini
    /// - Parameter eventLoop: The `EventLoop` that should be used to transform the `ResponseTransformable` to an `Response` if needed
    public func transformToResponse(on eventLoop: EventLoop) -> EventLoopFuture<Response<Self>> {
        eventLoop.makeSucceededFuture(.final(self))
    }
}


// MARK: EventLoopFuture + ResponseTransformable
extension EventLoopFuture: ResponseTransformable where Value: ResponseTransformable {
    public typealias Content = Value.Content
    
    public func transformToResponse(on eventLoop: EventLoop) -> EventLoopFuture<Response<Content>> {
        self.hop(to: eventLoop)
            .flatMap { value in
                value.transformToResponse(on: eventLoop)
            }
    }
}

extension EventLoopFuture where Value == Void {
    /// Transforms an `EventLoopFuture<Void>` into an Apodini `Status` that can be used to refine the response by the different exporters.
    ///
    /// If you want to return a more elaborate message to the client you should `map` the `EventLoopFuture` to a custom type conforming to `Encodable`.
    /// - Parameter status: The status that should be passed to the client
    /// - Returns: Returns an `EventLoopFuture` containing an Apodini `Response` type. The `Content`type is `Empty` and the response does not contain any instance that will be encoded in the response to the client.
    public func transform(to status: Status = .noContent) -> EventLoopFuture<Status> {
        map { _ in
            status
        }
    }
}


// MARK: - Primitive Types
extension String: ResponseTransformable {}
extension Int: ResponseTransformable {}
extension Int8: ResponseTransformable {}
extension Int16: ResponseTransformable {}
extension Int32: ResponseTransformable {}
extension Int64: ResponseTransformable {}
extension UInt: ResponseTransformable {}
extension UInt8: ResponseTransformable {}
extension UInt16: ResponseTransformable {}
extension UInt32: ResponseTransformable {}
extension UInt64: ResponseTransformable {}
extension Double: ResponseTransformable {}
extension Float: ResponseTransformable {}
extension Bool: ResponseTransformable {}
extension UUID: ResponseTransformable {}
extension Optional: ResponseTransformable where Wrapped: Encodable {}
extension Array: ResponseTransformable where Element: Encodable {}
extension Set: ResponseTransformable where Element: Encodable {}
extension Dictionary: ResponseTransformable where Key: Encodable, Value: Encodable {}
