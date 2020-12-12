//
//  File.swift
//
//
//  Created by Nityananda on 26.11.20.
//

import Runtime

/// ProtobufferBuilder builds `.proto` files.
///
/// Call `ProtobufferBuilder.description` for the final output.
public class ProtobufferBuilder {
    var messages: Set<Message>
    var services: Set<Service>
    
    /// Create an instance of `ProtobufferBuilder`.
    public init() {
        self.messages = Set()
        self.services = Set()
    }
}

public extension ProtobufferBuilder {
    /// `addService` builds a Protobuffer service declaration from the type parameter.
    /// - Parameter type: the type of the service
    /// - Throws: `Error`s of type `Exception`
    func addService(of type: Any.Type) throws {
        guard let node = try EnrichedInfo.tree(type) else {
            return
        }
        
        // Service.init...
        
        try node.children
            .filter(isParameter)
            .forEach { child in
                guard let first = child.value.typeInfo.genericTypes.first else {
                    return
                }
                
                try addMessage(of: first)
            }
    }
    
    func _addService<T>(of type: T.Type = T.self) throws {
        guard let serviceNode = try EnrichedInfo.tree(type).map(\.typeInfo) else {
            return
        }
        
        let serviceName = try serviceNode.value.compatibleName() + "Service"
        
        let messageTree = try EnrichedInfo.tree(type)
            .edited(fixArray)
            .filter {
                !ParticularType($0.typeInfo.type).isPrimitive
            }
            .map(Message.Property.init)
            .contextMap(Message.init)
        
        guard let message = messageTree?.value else {
            return
        }
        
        let voidMessage = Message.void
        let method = Service.Method(
            name: "handle",
            input: voidMessage,
            ouput: message
        )
        
        let service = Service(
            name: serviceName,
            methods: [method]
        )
        
        messages.insert(voidMessage)
        messages.insert(message)
        services.insert(service)
    }
    
    /// `addMessage` builds a Protobuffer message declaration from the type parameter.
    /// - Parameter type: the type of the message
    /// - Throws: `Error`s of type `Exception`
    func addMessage(of type: Any.Type) throws {
        let filtered = try EnrichedInfo.tree(type)
            .edited(fixArray)
            .edited(fixPrimitiveTypes)
            .map(Message.Property.init)
            .contextMap(Message.init)
            .filter(isNotPrimitive)
        
        if filtered.isEmpty {
            messages.insert(.scalar(type))
            return
        }
        
        filtered
            .reduce(into: Set()) { result, value in
                result.insert(value)
            }
            .forEach { element in
                messages.insert(element)
            }
    }
}

private extension Message {
    static let void = Message(name: "VoidMessage", properties: [])
    
    static func scalar(_ type: Any.Type) -> Message {
        Message(
            name: "\(type)Message",
            properties: [
                Property(
                    isRepeated: false,
                    name: "value",
                    typeName: "\(type)".lowercased(),
                    uniqueNumber: 1
                )
            ]
        )
    }
}

private func isNotPrimitive(_ message: Message) -> Bool {
    message.name.hasSuffix("Message")
}

private func isParameter(_ node: Node<EnrichedInfo>) -> Bool {
    ParticularType(node.value.typeInfo.type).description == "Parameter"
}
