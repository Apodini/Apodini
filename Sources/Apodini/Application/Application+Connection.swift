//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
//
// This code is based on the Vapor project: https://github.com/vapor/vapor
//
// SPDX-FileCopyrightText: 2020 Qutheory, LLC
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import NIO


extension Application {
    /// A Property identifying the `Connection` which provides an abstract view on the underlying protocol's state.
    ///
    /// This property only serves as a placeholder and should never be called.
    public var connection: Connection {
        get { fatalError("The connection should never be called directly") }
        set { fatalError("The connection cannot be manually set") } // swiftlint:disable:this unused_setter_value
    }
}

/// Represents the state of a connection to the client.
/// For non-client-streaming requests,
/// the default state should be `.end`.
public enum ConnectionState: String, Hashable {
    /// The request is part of a client stream,
    /// and there are more requests to follow.
    case open
    /// The request is the last in the current client stream.
    case end
    /// The previous request was the last request in the stream,
    /// and the client has now requested the stream be closed.
    /// - Note: This state exists to handle cases where a connection is closed after the last request has been received.
    ///         With some protocols (e.g. gRPC), it is not guaranteed that a client stream is always closed with a final request,
    ///         but instead the stream can also be kept open for some time after sending the last requesst, with a client then
    ///         eventually closing the stream by sending a request-less HTTP frame to the server.
    ///         In such cases (i.e. a stream being closed w/out there being an accompanying final request), the handler is invoked
    ///         once again, with this connection state.
    ///         It is guaranteed that a handler will be invoked with only the `end` state or with only the `close` state.
    ///         A hander will never be called for both of these states.
    case close
    
    /// The `ConnectionState` equality comparison functionl. Not recommended. Use a switch statement instead.
    /// - Note: The reason this exists is in order to deprecate it. Ideally, this enum would not conform to `Equatable`, and we'd require all
    ///         comparisons be done using switch statements, but that is impossible since enums (regardless of whether or not they have raw values),
    ///         will always get a compiler-synthesized `Equatable` implementation.
    ///         Why do we want to deprecate this function? The issue here is that we want handlers to correctly handle all possible connection states.
    ///         If a handler simply uses a `if connection.state == .end {} else {}` check, it'd miss `close` states, which would result
    ///         in the client not receiving the handler response. (The same also applies the other way around, i.e. a handler only checking for `state == .close`
    ///         and missing `end` states.
    ///         Requiring the handler to use a switch statement, on the other hand, means that (unless the handler uses a default case, which it shouldn't be doing anyway),
    ///         all possible connection states will be explicitly checked for in the handler, and responded to accordingly.
    @available(*, deprecated, message: "Use a switch statement instead!")
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.open, .open), (.end, .end), (.close, .close):
            return true
        default:
            return false
        }
    }
}


public func ~= (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
    switch (lhs, rhs) {
    case (.open, .open), (.end, .end), (.close, .close):
        return true
    default:
        return false
    }
}


/// All info related to client-connections
/// should be handled with the `Connection`.
/// Currently, this is only the state of the connection and the request.
public struct Connection {
    /// Holds the state of the current client-side stream.
    public var state: ConnectionState = .end
    /// Holds the latest `Request`
    public var request: Request
    /// The remote address of the client that created the request.
    public var remoteAddress: SocketAddress? { request.remoteAddress }
    /// The `EventLoop` the request is running on.
    public var eventLoop: EventLoop { request.eventLoop }
    /// The `Information` the request is carrying.
    public var information: InformationSet { request.information }
}
