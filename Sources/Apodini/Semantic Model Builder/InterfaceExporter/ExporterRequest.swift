//
// Created by Andreas Bauer on 09.01.21.
//

import NIO

/// The Protocol any Exporter Request type must conform to
public protocol ExporterRequest: Reducible {
    /// The remote address of the client that created the request.
    var remoteAddress: SocketAddress? { get }
    
    /// Additional information that is carried with the request
    var information: Set<AnyInformation> { get }
}

extension ExporterRequest {
    /// The remote address of the client that created the request.
    public var remoteAddress: SocketAddress? {
        nil
    }
    
    /// Additional information that is carried with the request
    public var information: Set<AnyInformation> {
        []
    }
}

/// When your `ExporterRequest` conforms to this protocol, it indicates that it delivers
/// its own `EventLoop` out of the box. Having that conformance you can use a shorthand
/// `ConnectionContext.handle(...)` method on without specifying an `EventLoop`.
public protocol ExporterRequestWithEventLoop: ExporterRequest {
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
