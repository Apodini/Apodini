//
//  Application+Connection.swift
//
//
//  Created by Moritz Schüll on 09.12.20.
//
// This code is based on the Vapor project: https://github.com/vapor/vapor
//
// The MIT License (MIT)
//
// Copyright (c) 2020 Qutheory, LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


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
public enum ConnectionState {
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
    var request: Request
}
