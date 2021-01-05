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
    var messages: Set<ProtoMessage>
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
    func addService(
        serviceName: String,
        inputType: Any.Type,
        returnType: Any.Type
    ) throws {
        let inputNode = try ProtoMessage.node(inputType)
        let outputNode = try ProtoMessage.node(returnType)
        
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
        
        let name = serviceName + "Service"
        let service = Service(
            name: name,
            methods: [method]
        )
        
        services.insert(service)
    }
}

internal extension ProtobufferBuilder {
    /// `addMessage` builds a Protobuffer message declaration from the type parameter.
    /// - Parameter type: the type of the message
    /// - Throws: `Error`s of type `Exception`
    func addMessage(messageType: Any.Type) throws {
        try ProtoMessage.node(messageType).forEach { element in
            messages.insert(element)
        }
    }
}

private extension ProtoMessage {
    static func node(_ type: Any.Type) throws -> Node<ProtoMessage> {
        let node = try EnrichedInfo.node(type)
            .edited(handleOptional)?
            .edited(handleArray)?
            .edited(handlePrimitiveType)?
            .map(ProtoMessage.Property.init)
            .contextMap(ProtoMessage.init)
            .compactMap { $0 }?
            .filter(isNotPrimitive)
        
        return node ?? Node(value: .scalar(type), children: [])
    }
    
    static func scalar(_ type: Any.Type) -> ProtoMessage {
        ProtoMessage(
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

private func isNotPrimitive(_ message: ProtoMessage) -> Bool {
    message.name.hasSuffix("Message")
}

private func isParameter(_ node: Node<EnrichedInfo>) -> Bool {
    ParticularType(node.value.typeInfo.type).description == "Parameter"
}
