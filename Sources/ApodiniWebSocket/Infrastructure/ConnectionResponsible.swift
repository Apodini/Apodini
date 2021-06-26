//
//  ConnectionResponsible.swift
//  
//
//  Created by Max Obermeier on 04.12.20.
//

@_implementationOnly import Vapor
import NIOWebSocket
import ApodiniUtils

typealias ContextOpener = (ConnectionResponsible, UUID) -> (ContextResponsible)

class ConnectionResponsible: Identifiable {
    unowned var websocket: Vapor.WebSocket
    
    let logger: Logger

    let request: Vapor.Request
    
    private let onClose: (ID) -> Void
    
    private var endpoints: [String: ContextOpener]
    
    private var contexts: [UUID: ContextResponsible] = [:]
    
    init(_ websocket: Vapor.WebSocket, request: Vapor.Request, onClose: @escaping (ID) -> Void, endpoints: [String: ContextOpener], logger: Logger) {
        self.websocket = websocket
        self.onClose = onClose
        self.endpoints = endpoints
        self.logger = logger
        self.request = request
        
        websocket.onText { websocket, message in
            var context: UUID?
            
            do {
                try self.processMessage(message: message, retrieving: &context)
            } catch {
                do {
                    guard let data = String(data: try error.message(on: context).encodeToJSON(), encoding: .utf8) else {
                        throw SerializationError.expectedUTF8
                    }
                    
                    websocket.send(data)
                } catch {
                    self.logger.report(error: error)
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
            let jsonData = try encoder.encode(EncodableServiceMessage(context: context, content: message))
            
            guard let data = String(data: jsonData, encoding: .utf8) else {
                throw SerializationError.expectedUTF8
            }
            
            self.websocket.send(data)
        } catch {
            self.logger.report(error: error)
        }
    }
    
    func send(_ error: Error, in context: UUID) {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(error.message(on: context))
            
            guard let data = String(data: jsonData, encoding: .utf8) else {
                throw SerializationError.expectedUTF8
            }
            
            self.websocket.send(data)
        } catch {
            self.logger.report(error: error)
        }
    }
    
    func close(_ code: WebSocketErrorCode) {
        _ = websocket.close(code: code)
    }
    
    func destruct(_ context: UUID) {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(CloseContextMessage(context: context))
            
            guard let data = String(data: jsonData, encoding: .utf8) else {
                throw SerializationError.expectedUTF8
            }
            
            self.websocket.send(data)
        } catch {
            self.logger.report(error: error)
        }
        
        self.contexts[context] = nil
    }
    
    private func processMessage(message: String, retrieving context: inout UUID?) throws {
        guard let data = message.data(using: .utf8) else {
            throw SerializationError.expectedUTF8
        }
        
        guard let rootObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw SerializationError.expectedObjectAtRoot
        }
        
        var errors: [SerializationError] = []
        
        do {
            try self.processOpenMessage(from: rootObject, retrieving: &context)
        } catch {
            try Self.handleSerializationError(error, using: &errors)
        }
        
        if !errors.isEmpty {
            do {
                try self.processClientMessage(from: rootObject, using: data, retrieving: &context)
                errors = []
            } catch {
                try Self.handleSerializationError(error, using: &errors)
            }
        }
        
        if !errors.isEmpty {
            do {
                try self.processCloseMessage(from: rootObject, retrieving: &context)
                errors = []
            } catch {
                try Self.handleSerializationError(error, using: &errors)
            }
        }
        
        if !errors.isEmpty {
            throw SerializationError.invalidMessageType(errors)
        }
    }
    
    private func processOpenMessage(from rootObject: [String: Any], retrieving context: inout UUID?) throws {
        let openMessage = try OpenContextMessage(json: rootObject)
        
        guard self.contexts[openMessage.context] == nil else {
            throw ProtocolError.openExistingContext(openMessage.context)
        }
        
        context = openMessage.context
        
        guard let opener = self.endpoints[openMessage.endpoint] else {
            throw ProtocolError.unknownEndpoint(openMessage.endpoint)
        }
        
        self.contexts[openMessage.context] = opener(self, openMessage.context)
    }
    
    private func processClientMessage(from rootObject: [String: Any], using data: Data, retrieving context: inout UUID?) throws {
        let clientMessage = try DecodableClientMessage(json: rootObject)
        
        guard let ctx = self.contexts[clientMessage.context] else {
            throw ProtocolError.unknownContext(clientMessage.context)
        }
        
        context = clientMessage.context
        
        try ctx.receive(clientMessage.parameters, data)
    }
    
    private func processCloseMessage(from rootObject: [String: Any], retrieving context: inout UUID?) throws {
        let closeMessage = try CloseContextMessage(json: rootObject)
        
        guard let ctx = self.contexts[closeMessage.context] else {
            return
        }
        
        context = closeMessage.context
        
        ctx.complete()
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

struct OpenContextMessage: Encodable {
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
    
    init(context: UUID, endpoint: String) {
        self.context = context
        self.endpoint = endpoint
    }
}

struct CloseContextMessage: Codable {
    var context: UUID
    
    init(context: UUID) {
        self.context = context
    }
    
    init(json: [String: Any]) throws {
        guard let context = UUID(uuidString: (json["context"] as? String) ?? "") else {
            throw SerializationError.missing("context")
        }
        
        self.context = context
    }
}

private struct DecodableClientMessage {
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

struct ClientMessage<I: Encodable>: Encodable {
    var context: UUID
    var parameters: I
}

private struct EncodableServiceMessage<C: Encodable>: Encodable {
    var context: UUID
    var content: C
}

struct ServiceMessage<C: Decodable>: Decodable {
    var context: UUID
    var content: C
}

struct ErrorMessage<E: Codable>: Codable {
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
