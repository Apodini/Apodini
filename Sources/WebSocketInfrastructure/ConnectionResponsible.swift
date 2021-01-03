//
//  ConnectionResponsible.swift
//  
//
//  Created by Max Obermeier on 04.12.20.
//

import Fluent
import Vapor
import NIOWebSocket

typealias ContextOpener = (ConnectionResponsible, UUID) -> (ContextResponsible)

class ConnectionResponsible: Identifiable {
    let websocket: WebSocket
    
    let database: Database?
    
    private let onClose: (ID) -> Void
    
    private var endpoints: [String: ContextOpener]
    
    private var contexts: [UUID: ContextResponsible] = [:]
    
    init(_ websocket: WebSocket, database: Database?, onClose: @escaping (ID) -> Void, endpoints: [String: ContextOpener]) {
        self.websocket = websocket
        self.database = database
        self.onClose = onClose
        self.endpoints = endpoints
        
        websocket.onText { _, message in
            var context: UUID?
            
            do {
                context = try self.parseMessage(message: message)
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
            
            self.websocket.send(data)
        } catch {
            print(error)
        }
    }
    
    func close(_ code: WebSocketErrorCode) {
        _ = websocket.close(code: code)
    }
    
    func destruct(_ context: UUID) {
        self.contexts[context] = nil
    }
    
    private func parseMessage(message: String) throws -> UUID? {
        var context: UUID?
        
        guard let data = message.data(using: .utf8) else {
            throw SerializationError.expectedUTF8
        }
        
        guard let rootObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw SerializationError.expectedObjectAtRoot
        }
        
        var errors: [SerializationError] = []
        
        do {
            context = try self.parseOpenMessage(from: rootObject)
        } catch {
            try Self.handleSerializationError(error, using: &errors)
        }
        
        if !errors.isEmpty {
            do {
                context = try self.parseClientMessage(from: rootObject, using: data)
                errors = []
            } catch {
                try Self.handleSerializationError(error, using: &errors)
            }
        }
        
        if !errors.isEmpty {
            do {
                context = try self.parseCloseMessage(from: rootObject)
                errors = []
            } catch {
                try Self.handleSerializationError(error, using: &errors)
            }
        }
        
        if !errors.isEmpty {
            throw SerializationError.invalidMessageType(errors)
        }
        
        return context
    }
    
    private func parseOpenMessage(from rootObject: [String: Any]) throws -> UUID {
        let openMessage = try OpenContextMessage(json: rootObject)
        
        guard let opener = self.endpoints[openMessage.endpoint] else {
            throw ProtocolError.unknownEndpoint(openMessage.endpoint)
        }
        
        guard self.contexts[openMessage.context] == nil else {
            throw ProtocolError.openExistingContext(openMessage.context)
        }
        
        self.contexts[openMessage.context] = opener(self, openMessage.context)
        
        return openMessage.context
    }
    
    private func parseClientMessage(from rootObject: [String: Any], using data: Data) throws -> UUID {
        let clientMessage = try ClientMessage(json: rootObject)
        
        guard let ctx = self.contexts[clientMessage.context] else {
            throw ProtocolError.unknownContext(clientMessage.context)
        }
        
        try ctx.receive(clientMessage.parameters, data)
        
        return clientMessage.context
    }
    
    private func parseCloseMessage(from rootObject: [String: Any]) throws -> UUID {
        let closeMessage = try CloseContextMessage(json: rootObject)
        
        guard let ctx = self.contexts[closeMessage.context] else {
            throw ProtocolError.unknownContext(closeMessage.context)
        }
        
        ctx.complete()
        
        return closeMessage.context
    }
    
    private static func handleSerializationError(_ error: Error, using errors: inout [SerializationError]) throws {
        if let serializationError = error as? SerializationError {
            errors.append(serializationError)
        } else {
            throw error
        }
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

// MARK: Message Types

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
