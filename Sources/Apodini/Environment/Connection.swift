//
//  Connection.swift
//  
//
//  Created by Moritz Schüll on 09.12.20.
//

import Foundation
@_implementationOnly import Runtime

enum ConnectionEnvironmentKey: EnvironmentKey {
    static var defaultValue = Connection()
}

extension EnvironmentValues {
    var connection: Connection {
        get { self[ConnectionEnvironmentKey.self] }
        set { self[ConnectionEnvironmentKey.self] = newValue }
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
     var state: ConnectionState = .end
}
