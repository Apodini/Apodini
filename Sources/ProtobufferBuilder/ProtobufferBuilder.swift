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
    func addService(of type: Any.Type, returning returnType: Any.Type) throws {
        guard let node = try EnrichedInfo.tree(type) else {
            return
        }
        
        // Service.init...
        guard let output = try Message.tree(returnType)?.value else {
            return
        }
        
        let _input: Tree<Message> = try node.children
            .filter(isParameter)
            .compactMap { child in
                guard let first = child.value.typeInfo.genericTypes.first else {
                    return nil
                }
                
                return try _addMessage(of: first)
            }
            .first
        
        guard let input = _input?.value else {
            return
        }
        
        let method = Service.Method(
            name: "handle",
            input: input,
            ouput: output
        )
        
        let service = Service(
            name: try node.value.typeInfo.compatibleName() + "Service",
            methods: [method]
        )
        
        services.insert(service)
    }
}

internal extension ProtobufferBuilder {
    /// `addMessage` builds a Protobuffer message declaration from the type parameter.
    /// - Parameter type: the type of the message
    /// - Throws: `Error`s of type `Exception`
    func addMessage(of type: Any.Type) throws {
        try Message.tree(type)
            .reduce(into: Set()) { result, value in
                result.insert(value)
            }
            .forEach { element in
                messages.insert(element)
            }
    }
}

private extension ProtobufferBuilder {
    @discardableResult
    func _addMessage(of type: Any.Type) throws -> Tree<Message> {
        let tree = try Message.tree(type)
        
        tree.reduce(into: Set()) { result, value in
                result.insert(value)
            }
            .forEach { element in
                messages.insert(element)
            }
        
        return tree
    }
}

private extension Message {
    static func tree(_ type: Any.Type) throws -> Tree<Message> {
        let filtered = try EnrichedInfo.tree(type)
            .edited(fixArray)
            .edited(fixPrimitiveTypes)
            .map(Message.Property.init)
            .contextMap(Message.init)
            .filter(isNotPrimitive)
        
        if filtered.isEmpty {
            return Node(value: .scalar(type), children: [])
        }
        
        return filtered
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
