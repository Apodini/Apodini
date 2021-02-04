//
// Created by Andreas Bauer on 09.01.21.
//

import protocol NIO.EventLoop

/// The Protocol any Exporter Request type must conform to
public protocol ExporterRequest: Reducible {}

/// When your `ExporterRequest` conforms to this protocol, it indicates that it delivers
/// its own `EventLoop` out of the box. Having that conformance you can use a shorthand
/// `ConnectionContext.handle(...)` method on without specifying an `EventLoop`.
public protocol WithEventLoop {
    /// Defines the associated `EventLoop`.
    var eventLoop: EventLoop { get }
}

/// An object that can merge itself and a `new` element
/// of same type.
public protocol Reducible {
    /// Called to reduce self with the given instance.
    /// Optional to implement. By default new will overwrite the existing instance.
    /// - Parameter new: The instance to be combined with.
    /// - Returns: The reduced instance.
    func reduce(to new: Self) -> Self
}

public extension Reducible {
    /// Default implementation.
    func reduce(to new: Self) -> Self {
        new
    }
}
