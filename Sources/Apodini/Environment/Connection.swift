//
//  Connection.swift
//  
//
//  Created by Moritz Schüll on 09.12.20.
//

import Foundation
@_implementationOnly import Runtime

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

/// The `@ClientConnection` property wrapper can be used
/// to allow a `Connection` object to be injected into `Component`s
/// by streaming-enabled exporters.
@propertyWrapper
public struct ClientConnection {
    /// The value for the `@ClientConnection` as
    /// injected by the exporter.
    public var wrappedValue: Connection

    /// Creates a new instance with connection state `.end`.
    public init() {
        self.wrappedValue = Connection(state: .end)
    }

    /// Creates a new instances with the given `ConnectionState`.
    public init(state: ConnectionState) {
        self.wrappedValue = Connection(state: state)
    }

    mutating func setConnection(_ connection: Connection) {
        wrappedValue = connection
    }
}

extension Component {
    /// Sets properties of the `Component` annotated with
    /// `@Connection` to the given connection value.
    /// - parameters:
    ///     - connection: The `Connection` that should be injected.
    func withConnection(_ connection: Connection) -> Self {
        var selfRef = self
        do {
            let info = try typeInfo(of: type(of: self))

            for property in info.properties {
                if var child = (try property.get(from: selfRef)) as? ClientConnection {
                    child.setConnection(connection)
                    try property.set(value: child, on: &selfRef)
                }
            }
        } catch {
            print(error)
        }
        return selfRef
    }
}
