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
    func addService<T>(of type: T.Type = T.self) throws {
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
    func addMessage<T>(of type: T.Type = T.self) throws {
        try EnrichedInfo.tree(type)
            .edited(fixArray)
            .edited(fixPrimitiveTypes)
            .compactMap({ try? Message.Property($0) })
            .contextMap(Message.init)
            .filter(isNotPrimitive)
            .reduce(into: Set()) { result, value in
                result.insert(value)
            }
            .forEach { element in
                self.messages.insert(element)
            }
    }
}

private extension Message {
    static let void = Message(name: "VoidMessage", properties: [])
}

private func isNotPrimitive(_ message: Message) -> Bool {
    message.name.hasSuffix("Message")
}
