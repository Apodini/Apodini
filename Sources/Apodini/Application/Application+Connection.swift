//
//  Connection.swift
//
//
//  Created by Moritz Schüll on 09.12.20.
//

import Foundation

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
/// the defautl state should be `.end`.
public enum ConnectionState {
    /// The request is part of a client stream,
    /// and there are more requestst to follow.
    case open
    /// The request is the last in the current client stream.
    case end
}

/// All info related to client-connections
/// should be handled with the `Connection`.
/// Currently, this is only the state of the connection.
public struct Connection {
    /// Holds the state of the current client-side stream.
    public var state: ConnectionState = .end
    
    /// Holds the latest `Request`
    var request: Request?
}
