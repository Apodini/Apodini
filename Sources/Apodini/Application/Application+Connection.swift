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
public enum ConnectionState: String {
    /// The request is part of a client stream,
    /// and there are more requests to follow.
    case open
    /// The request is the last in the current client stream.
    case end
}

/// All info related to client-connections
/// should be handled with the `Connection`.
/// Currently, this is only the state of the connection and the request.
public struct Connection {
    /// Holds the state of the current client-side stream.
    public var state: ConnectionState = .end
    /// The remote address of the client that created the request.
    public var remoteAddress: SocketAddress? { request.remoteAddress }
    /// The `EventLoop` the request is running on.
    public var eventLoop: EventLoop { request.eventLoop }
    /// The `Information` the request is carrying.
    public var information: InformationSet { request.information }
    
    /// Holds the latest `Request`
    public var request: Request
}
