//
//  Connection.swift
//  
//
//  Created by Moritz Schüll on 09.12.20.
//

import Foundation

enum ConnectionEnvironmentKey: EnvironmentKey {
    static var defaultValue: Connection = Connection()
}

extension EnvironmentValues {
    public var connection: Connection {
        get { self[ConnectionEnvironmentKey.self] }
        set { self[ConnectionEnvironmentKey.self] = newValue }
    }
}

public enum ConnectionState {
    /// .undefined is the default value.
    /// The connection state is undefined in a component's handler
    /// if the request was not a client streaming request.
    case undefined
    /// The request is part of a client stream,
    /// and there are more requestst to follow.
    case open
    /// The request is the last in the current client stream.
    case end
}

public struct Connection {
    /// Holds the state of the current client-side stream.
    var state: ConnectionState = .undefined
}
