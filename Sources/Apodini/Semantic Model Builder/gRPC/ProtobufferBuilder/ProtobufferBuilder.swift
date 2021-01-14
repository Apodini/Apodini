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
class ProtobufferBuilder {
    private(set) var messages: Set<ProtobufferMessage> = .init()
    private(set) var services: Set<ProtobufferService> = .init()
    
    func analyze<H: Handler>(endpoint: Endpoint<H>) throws {
        let serviceName = endpoint.serviceName
        let methodName = endpoint.methodName
        
        let inputNode: Node<ProtobufferMessage>
        
        switch endpoint.parameters.count {
        case 0:
            inputNode = try ProtobufferMessage.node(Void.self)
        case 1:
            inputNode = try ProtobufferMessage.node(
                endpoint.parameters[0].propertyType
            )
        default:
            inputNode = try ProtobufferMessage.node(H.self)
        }
        
        let outputNode = try ProtobufferMessage.node(endpoint.responseType)
        
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

extension ProtobufferBuilder {
    /// `addService` builds a Protobuffer service declaration from the type parameter.
    /// - Parameter type: the type of the service
    /// - Throws: `Error`s of type `Exception`
    func addService(
        serviceName: String,
        methodName: String,
        handlerType: Any.Type,
        returnType: Any.Type
    ) throws {
        let inputNode = try ProtobufferMessage.node(handlerType)
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
            .edited(handleParameter)?
            .edited(handleOptional)?
            .edited(handleArray)?
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
