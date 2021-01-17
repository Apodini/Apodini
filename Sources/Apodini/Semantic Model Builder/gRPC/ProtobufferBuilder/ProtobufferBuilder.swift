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
        
        let inputNode = try ProtobufferMessage.node(H.self)
            .with(uniqueNumberPreferences: endpoint.parameters.map {
                $0.options.option(for: .gRPC)?.fieldNumber
            })
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

internal extension ProtobufferMessage {
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

private extension Node where T == ProtobufferMessage {
    func with(uniqueNumberPreferences: [Int?]) -> Self {
        let propertiesWithPreference = zip(
            value.properties.sorted(by: \.uniqueNumber),
            uniqueNumberPreferences
        )
        .map { property, uniqueNumber in
            ProtobufferMessage.Property(
                fieldRule: property.fieldRule,
                name: property.name,
                typeName: property.typeName,
                uniqueNumber: uniqueNumber ?? property.uniqueNumber
            )
        }
        
        return Node(
            value: ProtobufferMessage(
                name: value.name,
                properties: Set(propertiesWithPreference)),
            children: children
        )
    }
}
