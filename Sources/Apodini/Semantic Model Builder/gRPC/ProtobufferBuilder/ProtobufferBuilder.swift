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
    var messages: Set<ProtobufferMessage>
    var services: Set<ProtobufferService>
    
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
        methodName: String,
        inputType: Any.Type,
        returnType: Any.Type
    ) throws {
        let inputNode = try ProtobufferMessage.node(inputType)
        let outputNode = try ProtobufferMessage.node(returnType)
        
        for node in [inputNode, outputNode] {
            node.forEach { element in
                messages.insert(element)
            }
        }
        
        let method = ProtobufferService.Method(
            name: methodName,
            input: inputNode.value,
            ouput: outputNode.value
        )

        let name = serviceName
        let service = ProtobufferService(
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
        try ProtobufferMessage.node(messageType).forEach { element in
            messages.insert(element)
        }
    }
}

private extension ProtobufferMessage {
    static func node(_ type: Any.Type) throws -> Node<ProtobufferMessage> {
        let node = try EnrichedInfo.node(type)
            .edited(handlePrimitiveType)?
            .map(ProtobufferMessage.Property.init)
            .contextMap(ProtobufferMessage.init)
            .compactMap { $0 }?
            .filter(isNotPrimitive)
        
        return node ?? Node(value: .scalar(type), children: [])
    }
    
    static func scalar(_ type: Any.Type) -> ProtobufferMessage {
        ProtobufferMessage(
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

private func isNotPrimitive(_ message: ProtobufferMessage) -> Bool {
    message.name.hasSuffix("Message")
}
