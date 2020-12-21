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
    
    let ws: WebSocket
    
    private let onClose: (ID) -> ()
    
    private var endpoints: [String: ContextOpener]
    
    private var contexts: [UUID: ContextResponsible] = [:]
    
    init(_ websocket: WebSocket, onClose: @escaping (ID) -> (), endpoints: [String: ContextOpener]) {
        self.ws = websocket
        self.onClose = onClose
        self.endpoints = endpoints
        
        websocket.onText { ws, message in
            var context: UUID?
            
            do {
                guard let data = message.data(using: .utf8) else {
                    throw SerializationError.expectedUTF8
                }
                let a = try JSONSerialization.jsonObject(with: data, options: [])
                
                guard let o = a as? [String: Any] else {
                    throw SerializationError.expectedObjectAtRoot
                }
                
                var errors: [SerializationError] = []
                
                do {
                    let openMessage = try OpenContextMessage(json: o)
                    
                    guard let opener = self.endpoints[openMessage.endpoint] else {
                        throw ProtocolError.unknownEndpoint(openMessage.endpoint)
                    }
                    
                    guard self.contexts[openMessage.context] == nil else {
                        throw ProtocolError.openExistingContext(openMessage.context)
                    }
                    context = openMessage.context
                    
                    self.contexts[openMessage.context] = opener(self, openMessage.context)
                } catch {
                    if let serializationError = error as? SerializationError {
                        errors.append(serializationError)
                    } else {
                        throw error
                    }
                }
                
                if !errors.isEmpty {
                    do {
                        let clientMessage = try ClientMessage(json: o)
                        
                        context = clientMessage.context
                        
                        guard let ctx = self.contexts[clientMessage.context] else {
                            throw ProtocolError.unknownContext(clientMessage.context)
                        }
                        
                        try ctx.receive(clientMessage.parameters)
                        errors = []
                    } catch {
                        if let serializationError = error as? SerializationError {
                            errors.append(serializationError)
                        } else {
                            throw error
                        }
                    }
                }
                
                if !errors.isEmpty {
                    do {
                        let closeMessage = try CloseContextMessage(json: o)
                            
                        context = closeMessage.context
                        
                        guard let ctx = self.contexts[closeMessage.context] else {
                            throw ProtocolError.unknownContext(closeMessage.context)
                        }
                        
                        ctx.complete()
                        errors = []
                    } catch {
                        if let serializationError = error as? SerializationError {
                            errors.append(serializationError)
                        } else {
                            throw error
                        }
                    }
                }
                
                if !errors.isEmpty {
                    throw SerializationError.invalidMessageType(errors)
                }
            } catch {
                do {
                    guard let data = String(data: try error.message(on: context).toJSONData(), encoding: .utf8) else {
                        throw SerializationError.expectedUTF8
                    }
                    
                    websocket.send(data)
                } catch {
                    print(error)
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

private enum ProtocolError: WSError {
    case unknownEndpoint(String)
    case unknownContext(UUID)
    case openExistingContext(UUID)
    
    var reason: String {
        switch self {
        case .unknownContext(let context):
            return "Unknown context \(context)"
        case .openExistingContext(let context):
            return "Context \(context) does already exist and cannot be opened again"
        case .unknownEndpoint(let endpoint):
            return "Unknown endpoint \(endpoint)"
        }
    }
}

private indirect enum SerializationError: WSError {
    case expectedUTF8
    case expectedObjectAtRoot
    case missing(String)
    case invalidMessageType([SerializationError])
    
    var reason: String {
        switch self {
        case .expectedUTF8:
            return "expected utf-8"
        case .expectedObjectAtRoot:
            return "expected root element to be an object"
        case .missing(let property):
            return "missing property \(property) on root element"
        case .invalidMessageType(let errors):
            return "Wrong format - possible reasons: \(errors.map { $0.reason }.joined(separator: ", "))"
            
        }
    }
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

private struct ServiceMessage<C: Encodable>: Encodable {
    var context: UUID
    var content: C
}

private struct ErrorMessage<E: Encodable>: Encodable {
    var context: UUID?
    var error: E
}

private extension Error {
    func message(on context: UUID?) -> ErrorMessage<String> {
        if let wserr = self as? WSError {
            return ErrorMessage(context: context, error: wserr.reason)
        } else {
            #if DEBUG
            return ErrorMessage(context: context, error: self.localizedDescription)
            #else
            return ErrorMessage(context: context, error: "Undefined error")
            #endif
        }
    }
}

private extension Encodable {
    func toJSONData() -> Data? { try? JSONEncoder().encode(self) }
    func toJSONData() throws -> Data { try JSONEncoder().encode(self) }
}

