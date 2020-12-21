//
//  Connection.swift
//  
//
//  Created by Moritz Schüll on 09.12.20.
//

import Foundation
@_implementationOnly import Runtime

public enum ConnectionState {
    /// The request is part of a client stream,
    /// and there are more requestst to follow.
    case open
    /// The request is the last in the current client stream.
    case end
}

public struct Connection {
     /// Holds the state of the current client-side stream.
     var state: ConnectionState = .end
}

@propertyWrapper
public struct ClientConnection {
    public var wrappedValue: Connection

    public init() {
        self.wrappedValue = Connection(state: .end)
    }

    public init(state: ConnectionState) {
        self.wrappedValue = Connection(state: state)
    }

    public mutating func setConnection(_ connection: Connection) {
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
