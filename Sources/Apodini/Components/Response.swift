//
// Created by Andi on 01.01.21.
//

import Foundation
import NIO


/// A common `Response` type that all types returned from a `handle()` method in a `Handler` have to conform to.
///
/// Common types like `String`, `Int` , `Double`, `Float`,`Bool`, and `UUID` and the corresponding `EventLoopFuture`wrappers all confrom to `Response` out of the box.
/// Types that confrom to `Encodable` can confrom to `Response` without the need to implement any additional methods.
public protocol Response {
    /// The `Encodable` type that is returned from a `handle()` method in a `Handler`.
    /// The type can be wrapped by an `EventLoopFuture` or an `Action`.
    associatedtype ResponseContent: Encodable
    
    /// Transforms an `Response` into an `Action` to be processed by the Apodini
    /// - Parameter eventLoop: The `EventLoop` that should be used to transform the `Response` to an `Action` if needed
    func action(on eventLoop: EventLoop) -> EventLoopFuture<Action<ResponseContent>>
}


// MARK: Response for Generic Encodable Types
extension Encodable {
    /// Default Implementation for types conforming to `Response`
    /// 
    /// The `Encodable` type that is returned from a `handle()` method in a `Handler`.
    /// The type can be wrapped by an `EventLoopFuture` or an `Action`.
    public typealias ResponseContent = Self
    
    /// Default Implementation for types conforming to `Response`
    ///
    /// Transforms an `Response` into an `Action` to be processed by the Apodini
    /// - Parameter eventLoop: The `EventLoop` that should be used to transform the `Response` to an `Action` if needed
    public func action(on eventLoop: EventLoop) -> EventLoopFuture<Action<Self>> {
        eventLoop.makeSucceededFuture(.automatic(self))
    }
}


// MARK: EventLoopFuture + Response
extension EventLoopFuture: Response where Value: Response {
    public typealias ResponseContent = Value.ResponseContent
    
    public func action(on eventLoop: EventLoop) -> EventLoopFuture<Action<ResponseContent>> {
        flatMap { value in
            value.action(on: eventLoop)
        }
    }
}

// MARK: - Optional Types
extension Optional: Response where Wrapped: Encodable {
    public typealias ResponseContent = Self
    
    public func action(on eventLoop: EventLoop) -> EventLoopFuture<Action<ResponseContent>> {
        eventLoop.makeSucceededFuture(.automatic(self))
    }
}


// MARK: - Collection Types
// MARK: Array + Response
extension Array: Response where Element: Encodable {
    public typealias ResponseContent = [Element]
    
    public func action(on eventLoop: EventLoop) -> EventLoopFuture<Action<ResponseContent>> {
        eventLoop.makeSucceededFuture(.automatic(self))
    }
}


// MARK: Dictionary + Response
extension Dictionary: Response where Key: Encodable, Value: Encodable {
    public typealias ResponseContent = [Key: Value]
    
    public func action(on eventLoop: EventLoop) -> EventLoopFuture<Action<ResponseContent>> {
        eventLoop.makeSucceededFuture(.automatic(self))
    }
}


// MARK: - Primitive Types
extension String: Response {}
extension Int: Response {}
extension Double: Response {}
extension Float: Response {}
extension Bool: Response {}
extension UUID: Response {}
