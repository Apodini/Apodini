//
//  Connection.swift
//  
//
//  Created by Moritz Schüll on 09.12.20.
//

import Foundation

enum ConnectionEnvironmentKey: EnvironmentKey {
    static var defaultValue = Connection()
}

extension EnvironmentValues {
    var connection: Connection {
        get { self[ConnectionEnvironmentKey.self] }
        set { self[ConnectionEnvironmentKey.self] = newValue }
    }
}

enum ConnectionState {
    /// The request is part of a client stream,
    /// and there are more requestst to follow.
    case open
    /// The request is the last in the current client stream.
    case end
}

struct Connection {
    /// Holds the state of the current client-side stream.
    var state: ConnectionState = .end
}
