//
//  Client.swift
//  
//
//  Created by Max Obermeier on 05.01.21.
//

import Foundation
@_implementationOnly import Vapor
@_implementationOnly import Logging

/// A stateless client-implementation to `VaporWSRouter`. It cannot react to responses
/// from the server but only collect them for the caller.
struct StatelessClient {
    private let address: String
    
    private let logger: Logger
    
    private let eventLoop: EventLoop
    
    private let ignoreErrors: Bool
    
    /// Create a `StatelessClient` that will connect to the given `address` once used. All operations
    /// are executed on the given `eventLoop`.
    init(address: String = "ws://localhost:8080/apodini/websocket", on eventLoop: EventLoop, ignoreErrors: Bool = false) {
        self.address = address
        var logger = Logger(label: "org.apodini.websocket.client")
        #if DEBUG
        logger.logLevel = .debug
        #endif
        self.logger = logger
        self.eventLoop = eventLoop
        self.ignoreErrors = ignoreErrors
    }
    
    /// Opens a new WebSocket connection, creates a new context on the given `endpoint` and sends
    /// one client-message carrying `input`. Afterwards it sends a close-context-message. The future
    /// completes when the client receives a close-content-message from the server. The future contains
    /// the first server-message received on the relevant context. If so server-message was received, the
    /// future fails.
    func resolve<I: Encodable, O: Decodable>(one input: I, on endpoint: String) -> EventLoopFuture<O> {
        self.resolve(input, on: endpoint).flatMapThrowing { (response: [O]) in
            guard let first = response.first else {
                throw ServerError.noMessage
            }
            return first
        }
    }
    
    /// Opens a new WebSocket connection, creates a new context on the given `endpoint` and sends
    /// one client message for each element in `input`. Afterwards it sends a close-context-message. The future
    /// completes when the client receives a close-content-message from the server. The future contains
    /// all server-messages received on the relevant context.
    func resolve<I: Encodable, O: Decodable>(_ inputs: I..., on endpoint: String) -> EventLoopFuture<[O]> {
        resolve(many: inputs, on: endpoint)
    }
    
    /// Opens a new WebSocket connection, creates a new context on the given `endpoint` and sends
    /// one client message for each element in `input`. Afterwards it sends a close-context-message. The future
    /// completes when the client receives a close-content-message from the server. The future contains
    /// all server-messages received on the relevant context.
    func resolve<I: Encodable, O: Decodable>(many inputs: [I], on endpoint: String) -> EventLoopFuture<[O]> {
        let response = eventLoop.makePromise(of: [O].self)
        var responses: [O] = []
        
        _ = Vapor.WebSocket.connect(
            to: self.address,
            on: eventLoop
        ) { websocket in
            let contextId = UUID()
            let contextPromise = eventLoop.makePromise(of: Void.self)
            self.sendOpen(context: contextId, on: endpoint, to: websocket, promise: contextPromise)
            
            contextPromise.futureResult.whenComplete { result in
                switch result {
                case .failure(let error):
                    response.fail(error)
                    // close connection
                    _ = websocket.close()
                case .success:
                    self.send(messages: inputs, on: contextId, to: websocket, promise: response)
                    self.sendClose(context: contextId, to: websocket, promise: response)
                }
            }

            websocket.onText { websocket, string in
                self.onText(websocket: websocket, string: string, context: contextId, promise: response, responses: &responses)
            }
            
            var done = false
            response.futureResult.whenSuccess { _ in
                done = true
            }
            
            websocket.onClose.whenComplete { _ in
                if !done {
                    response.fail(ServerError.noMessage)
                }
            }
        }
        
        return response.futureResult
    }
    
    private func sendOpen(context: UUID, on endpoint: String, to websocket: Vapor.WebSocket, promise: EventLoopPromise<Void>) {
        do {
            // create context on user endpoint
            let message = try encode(OpenContextMessage(context: context, endpoint: endpoint))
            self.logger.debug(">>> \(message)")
            websocket.send(message, promise: promise)
        } catch {
            promise.fail(error)
        }
    }
    
    private func send<I: Encodable, O>(messages: [I], on context: UUID, to websocket: Vapor.WebSocket, promise: EventLoopPromise<O>) {
        for input in messages {
            do {
                let message = try encode(ClientMessage(context: context, parameters: input))
                self.logger.debug(">>> \(message)")
                // create context on user endpoint
                websocket.send(message)
            } catch {
                promise.fail(error)
                // close connection
                _ = websocket.close()
            }
        }
    }
    
    private func sendClose<O>(context: UUID, to websocket: Vapor.WebSocket, promise: EventLoopPromise<O>) {
        do {
            let message = try encode(CloseContextMessage(context: context))
            self.logger.debug(">>> \(message)")
            // announce end of client-messages
            websocket.send(message)
        } catch {
            promise.fail(error)
            // close connection
            _ = websocket.close()
        }
    }
    
    private func onText<O: Decodable>(
        websocket: Vapor.WebSocket,
        string: String,
        context: UUID,
        promise: EventLoopPromise<[O]>,
        responses: inout [O]
    ) {
        self.logger.debug("<<< \(string)")
        
        guard let data = string.data(using: .utf8) else {
            promise.fail(ConversionError.couldNotDecodeUsingUTF8)
            // close connection
            _ = websocket.close()
            return
        }

        do {
            let result = try JSONDecoder().decode(ServiceMessage<O>.self, from: data)
            if result.context == context {
                responses.append(result.content)
            }
        } catch {
            do {
                let result = try JSONDecoder().decode(ErrorMessage<String>.self, from: data)
                if (result.context == context || result.context == nil) && !self.ignoreErrors {
                    promise.fail(ServerError.message(result.error))
                    // close connection
                    _ = websocket.close()
                    return
                }
            } catch {
                do {
                    let result = try JSONDecoder().decode(CloseContextMessage.self, from: data)
                    if result.context == context {
                        promise.succeed(responses)
                        // close connection
                        _ = websocket.close()
                    }
                } catch { }
            }
        }
    }
}

private enum ServerError: Error {
    case message(String)
    case noMessage
}

private enum ConversionError: String, Error {
    case couldNotEncodeUsingUTF8
    case couldNotDecodeUsingUTF8
}

private func encode<M: Encodable>(_ message: M) throws -> String {
    let data = try JSONEncoder().encode(message)
    
    guard let stringMessage = String(data: data, encoding: String.Encoding.utf8) else {
        throw ConversionError.couldNotEncodeUsingUTF8
    }
    
    return stringMessage
}
