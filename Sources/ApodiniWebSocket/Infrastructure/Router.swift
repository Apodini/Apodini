//
//  Router.swift
//  
//
//  Created by Max Obermeier on 03.12.20.
//

@_implementationOnly import Vapor
import NIOWebSocket
@_implementationOnly import OpenCombine
@_implementationOnly import Logging

/// An error type that receives special treatment by the router. The router sends the
/// `reason` to the client if it receives a `WSError` on the `output`. Other error
/// types will only be exposed in `DEBUG` mode, otherwise a generic error message
/// is sent.
protocol WSError: Error {
    var reason: String { get }
}

/// An error type that receives special treatment by the router when sent as a
/// `completion` on the `output`.  The contained `code` is used to close the
/// connection.
protocol WSClosingError: WSError {
    var code: WebSocketErrorCode { get }
}

/// This type defines the `output` that can be sent over an `register`ed connection.
/// A message can carry an object of fixed type `T` or an `error`.
enum Message<T> {
    /// Send a message of type `T`
    case message(T)
    /// Send an error message **without** closing the connection.
    case error(Error)
}

/// A `Router` provides an endpoint-based, typed abstraction of a WebSocket connection. It uses
/// a spcific `Input` for each `register`ed endpoint to maintain state and possibly also check
/// validity of incoming messages. Each endpoint is identified by its `identifier`.
protocol Router {
    /// A `Router`-specific type that carries information about an incoming connection.
    associatedtype ConnectionInformation
    
    /// Register a new endpoint on the given `identifier` using the given `opener` when a
    /// new client connects. Closing the connection may be requested by the client (a completion is sent
    /// on the input publisher) and can be executed by the server (a completion is sent on the `output`).
    func register<I: Input, O: Encodable>(
        _ opener: @escaping (AnyPublisher<I, Never>, EventLoop, ConnectionInformation) ->
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
/// **`CloseContextMessage`:** Closes the context with the given `<UUID>`. This message-type must
/// be sent by both, client and server. Sending this message means "I am not going to send another message
/// on this context".
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
final class VaporWSRouter: Router {
    typealias ConnectionInformation = Vapor.Request
    
    private var registeredAtVapor = false
    
    private let app: Application
    
    private let logger: Logger
    
    private let path: [PathComponent]
    
    private var endpoints: [String: ContextOpener] = [:]
    
    private var connections: [ConnectionResponsible.ID: ConnectionResponsible] = [:]
    private let connectionsMutex = NSLock()

    init(
        _ app: Application,
        logger: Logger = .init(label: "org.apodini.websocket.vapor_ws_router"),
        at path: String
    ) {
        self.app = app
        self.logger = logger
        self.path = path.pathComponents
    }
    
    /// - Note: If the `output`'s `completion` is `finished`, only the `context` is closed. If it is
    /// `failure` the whole connection is closed. By default the `WebSocketErrorCode` used to close
    /// the connection is `unexpectedServerError`. A `WSClosingError` can be used to specifiy a
    /// different code.
    func register<I: Input, O: Encodable>(
        _ opener: @escaping (AnyPublisher<I, Never>, EventLoop, ConnectionInformation) ->
            (default: I, output: AnyPublisher<Message<O>, Error>),
        on identifier: String) {
        if self.endpoints[identifier] != nil {
            self.logger.warning("Endpoint \(identifier) on VaporWSRouter registered at \(path.string) was registered more than once.")
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
        app.routes.grouped(self.path).webSocket(onUpgrade: { req, websocket in
            self.connectionsMutex.lock()
            let responsible = ConnectionResponsible(
                websocket,
                request: req,
                onClose: { id in
                    self.connectionsMutex.lock()
                    self.connections[id] = nil
                    self.connectionsMutex.unlock()
                },
                endpoints: self.endpoints,
                logger: self.logger
            )
            self.connections[responsible.id] = responsible
            self.connectionsMutex.unlock()
        })
    }
}
