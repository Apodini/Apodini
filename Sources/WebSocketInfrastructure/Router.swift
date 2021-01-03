//
//  Router.swift
//  
//
//  Created by Max Obermeier on 03.12.20.
//

import Fluent
import Vapor
import NIOWebSocket
import OpenCombine

/// An error type that receives special treatment by the router. The router sends the
/// `reason` to the client if it receives a `WSError` on the `output`. Other error
/// types will only be exposed in `DEBUG` mode, otherwise a generic error message
/// is sent.
public protocol WSError: Error {
    var reason: String { get }
}

/// This type defines the `output` that can be sent over an `register`ed connection.
/// A message can carry an object of fixed type `T` or an `error`.
public enum Message<T> {
    /// Send a message of type `T`
    case message(T)
    /// Send an error message **without** closing the connection.
    case error(Error)
}

/// A `Router` provides an endpoint-based, typed abstraction of a WebSocket connection. It uses
/// a spcific `Input` for each `register`ed endpoint to maintain state and possibly also check
/// validity of incoming messages. Each endpoint is identified by its `identifier`.
public protocol Router {
    /// Register a new endpoint on the given `identifier` using the given `opener` when a
    /// new client connects. Closing the connection may be requested by the client (a completion is sent
    /// on the input publisher) and can be executed by the server (a completion is sent on the `output`).
    func register<I: Input, O: Encodable>(
        _ opener: @escaping (AnyPublisher<I, Never>, EventLoop, Database?) ->
            (default: I, output: AnyPublisher<Message<O>, Error>),
        on identifier: String)
}

/// A `Router` that is based on Vapor's WebSocket API. It only exposes one HTTP endpoint that runs
/// a context- and endpoint-based protocol to conform to the requirements of `Router`. This protocol
/// features five types of messages:
///
/// **`OpenContextMessage`:** Opens a new context (wich is identified by `<UUID>`) on a virtual
/// endpoint (which is identified by the `<identifier>`). The `<identifier>` refers to the
/// `identifier` on the `register` method. This message-type may be sent by either client or
/// server.
///
///     {
///         "context": "<UUID>",
///         "endpoint": "<identifier>"
///     }
///
/// **`CloseContextMessage`:** Closes the context with the given `<UUID>`. This message-type may
/// be sent by either client or server.
///
///     {
///         "context": "<UUID>"
///     }
///
/// **`ClientMessage`:** Sends input to a speficic `context`. The `parameters` must fit the
/// `Input` required by the `context`'s `endpoint` in it's current state. This message-type is only
/// used by the client.
///
///     {
///         "context": "<UUID>",
///         "parameters": {
///             "<name1>": <value2>,
///             "<name2>": <value2>,
///             ...
///         }
///     }
///
/// **`ServiceMessage`:** Sends output to a speficic `context`. The `content` is of type `O` as
/// defined on the call to `register` that corresponds to the given `context`'s `endpoint`. This
/// message-type is only used by the server.
///
///     {
///         "context": "<UUID>",
///         "content": <Content>
///     }
///
/// **`ErrorMessage`:** Sends an error-message to a speficic `context`. This message-type is only
/// used by the server.
///
///     {
///         "context": "<UUID>",
///         "error": <Errors>
///     }
///
public class VaporWSRouter: Router {
    private var registeredAtVapor: Bool = false
    
    private let app: Application
    
    private let path: [PathComponent]
    
    private var endpoints: [String: ContextOpener] = [:]
    
    private var connections: [ConnectionResponsible.ID: ConnectionResponsible] = [:]
    private let connectionsMutex = NSLock()

    public init(_ app: Application, at path: [PathComponent] = ["apodini", "websocket"]) {
        self.app = app
        self.path = path
    }
    
    public func register<I: Input, O: Encodable>(
        _ opener: @escaping (AnyPublisher<I, Never>, EventLoop, Database?) ->
            (default: I, output: AnyPublisher<Message<O>, Error>),
        on identifier: String) {
        if self.endpoints[identifier] != nil {
            print("Endpoint \(identifier) on VaporWSRouter registered at \(path.string) was registered more than once.")
        }
        
        self.endpoints[identifier] = { con, ctx in
            TypeSafeContextResponsible(opener, con: con, context: ctx)
        }
        
        if !registeredAtVapor {
            self.registeredAtVapor = true
            self.registerRouteToVapor()
        }
    }
    
    
    private func registerRouteToVapor() {
        app.routes.grouped(self.path).webSocket(onUpgrade: { _, websocket in
            self.connectionsMutex.lock()
            let responsible = ConnectionResponsible(
                websocket,
                database: nil,
                onClose: { id in
                    self.connectionsMutex.lock()
                    self.connections[id] = nil
                    self.connectionsMutex.unlock()
                },
                endpoints: self.endpoints
            )
            self.connections[responsible.id] = responsible
            self.connectionsMutex.unlock()
        })
    }
}
