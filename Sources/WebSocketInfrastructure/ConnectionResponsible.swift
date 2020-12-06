//
//  ConnectionResponsible.swift
//  
//
//  Created by Max Obermeier on 04.12.20.
//

import Vapor
import NIOWebSocket

typealias ContextOpener = (ConnectionResponsible, UUID) -> (ContextResponsible)

class ConnectionResponsible: Identifiable {
    
    private let ws: WebSocket
    
    private let onClose: (ID) -> ()
    
    private var endpoints: [String: ContextOpener]
    
    private var contexts: [UUID: ContextResponsible] = [:]
    
    init(_ websocket: WebSocket, onClose: @escaping (ID) -> (), endpoints: [String: ContextOpener]) {
        self.ws = websocket
        self.onClose = onClose
        self.endpoints = endpoints
        
        websocket.onText { ws, message in
            do {
                guard let data = message.data(using: .utf8) else {
                    throw SerializationError.expectedUTF8
                }
                let a = try JSONSerialization.jsonObject(with: data, options: [])
                
                guard let o = a as? [String: Any] else {
                    throw SerializationError.expectedObjectAtRoot
                }
                
                if let openMessage = try? OpenContextMessage(json: o) {
                    print(self.endpoints)
                    guard let opener = self.endpoints[openMessage.endpoint] else {
                        throw ProtocolError.unknownEndpoint(openMessage.endpoint)
                    }
                    
                    guard self.contexts[openMessage.context] == nil else {
                        throw ProtocolError.openExistingContext(openMessage.context)
                    }
                    
                    self.contexts[openMessage.context] = opener(self, openMessage.context)
                    
                } else if let clientMessage = try? ClientMessage(json: o) {
                    guard let ctx = self.contexts[clientMessage.context] else {
                        throw ProtocolError.unknownContext(clientMessage.context)
                    }
                    
                    ctx.receive(clientMessage.parameters)
                    
                } else if let closeMessage = try? CloseContextMessage(json: o) {
                    guard let ctx = self.contexts[closeMessage.context] else {
                        throw ProtocolError.unknownContext(closeMessage.context)
                    }
                    
                    ctx.complete()
                    
                } else {
                    throw SerializationError.invalidMessageType
                }
            } catch {
                let p = ws.eventLoop.makePromise(of: Void.self)
                websocket.send(error.localizedDescription, promise: p)
                p.futureResult.whenComplete { _ in
                    _ = websocket.close(code: .unacceptableData)
                }
            }
        }
        
        _ = websocket.onClose.map {
            onClose(self.id)
        }
    }
    
    func send<D: Encodable>(_ message: D, in context: UUID) {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(ServiceMessage(context: context, content: message))
            
            guard let data = String(data: jsonData, encoding: .utf8) else {
                throw SerializationError.expectedUTF8
            }
            
            self.ws.send(data)
        } catch {
            print(error)
        }
    }
    
    func close(_ code: WebSocketErrorCode) {
        _ = ws.close(code: code)
    }
    
    func destruct(_ context: UUID) {
        self.contexts[context] = nil
    }
    
}

private enum ProtocolError: Error {
    case unknownEndpoint(String)
    case unknownContext(UUID)
    case openExistingContext(UUID)
}

private enum SerializationError: Error {
    case expectedUTF8
    case expectedObjectAtRoot
    case missing(String)
    case invalid(String, Any)
    case invalidMessageType
}



private struct OpenContextMessage {
    var context: UUID
    var endpoint: String
    
    init(json: [String: Any]) throws {
        guard let context = UUID(uuidString: (json["context"] as? String) ?? "") else {
            throw SerializationError.missing("context")
        }
        
        guard let endpoint = json["endpoint"] as? String else {
            throw SerializationError.missing("endpoint")
        }
        
        self.context = context
        self.endpoint = endpoint
    }
}

private struct CloseContextMessage {
    var context: UUID
    
    init(json: [String: Any]) throws {
        guard let context = UUID(uuidString: (json["context"] as? String) ?? "") else {
            throw SerializationError.missing("context")
        }
        
        self.context = context
    }
}

private struct ClientMessage {
    var context: UUID
    var parameters: [String: Any]
    
    init(json: [String: Any]) throws {
        guard let context = UUID(uuidString: (json["context"] as? String) ?? "") else {
            throw SerializationError.missing("context")
        }
        
        guard let parameters = json["parameters"] as? [String: Any] else {
            throw SerializationError.missing("parameters")
        }
        
        self.context = context
        self.parameters = parameters
    }
}

private struct ServiceMessage<D: Encodable>: Encodable {
    
    var context: UUID
    var content: D
        
}


extension Encodable {
    func toJSONData() -> Data? { try? JSONEncoder().encode(self) }
}
