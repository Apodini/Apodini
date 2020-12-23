//
//  File.swift
//
//
//  Created by Nityananda on 26.11.20.
//

@_implementationOnly import Runtime

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
        let node = try EnrichedInfo.node(type)
        let parameter = node.children
            .filter(isParameter)
            .compactMap { node in
                node.value.typeInfo.genericTypes.first
            }
            .first
        let inputType = parameter ?? Void.self
        
        let inputNode = try Message.node(inputType)
        let outputNode = try Message.node(returnType)
        
        for node in [inputNode, outputNode] {
            node.forEach { element in
                messages.insert(element)
            }
        }
        
        let method = Service.Method(
            name: "handle",
            input: inputNode.value,
            ouput: outputNode.value
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
        try Message.node(type).forEach { element in
            messages.insert(element)
        }
    }
}

private extension Message {
    static func node(_ type: Any.Type) throws -> Node<Message> {
        let node = try EnrichedInfo.node(type)
            .edited(fixOptional)?
            .edited(fixArray)?
            .edited(fixPrimitiveTypes)?
            .map(Message.Property.init)
            .contextMap(Message.init)
            .compactMap { $0 }?
            .filter(isNotPrimitive)
        
        return node ?? Node(value: .scalar(type), children: [])
    }
    
    static func scalar(_ type: Any.Type) -> Message {
        Message(
            name: "\(type)Message",
            properties: [
                Property(
                    fieldRule: .required,
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
