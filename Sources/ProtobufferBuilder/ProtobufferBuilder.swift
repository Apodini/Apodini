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
        guard let serviceNode = try Tree<TypeInfo>.make(type) else { return }
        
        let serviceName = try serviceNode.value.compatibleName() + "Service"
        
        let messageTree = try Tree<TypeInfo>.make(type)
            .edited(fixArray)
            .filter { typeInfo in
                !ParticularType(typeInfo.type).isPrimitive
            }
            .map { typeInfo in
                try Message(typeInfo: typeInfo)
            }
        
        guard let message = messageTree?.value else { return }
        
        let method = Service.Method(
            name: "handle",
            input: .void,
            ouput: message
        )
        
        let service = Service(
            name: serviceName,
            methods: [method]
        )
        
        messages.insert(message)
        services.insert(service)
    }
    
    /// `addMessage` builds a Protobuffer message declaration from the type parameter.
    /// - Parameter type: the type of the message
    /// - Throws: `Error`s of type `Exception`
    func addMessage<T>(of type: T.Type = T.self) throws {
        try Tree<TypeInfo>.make(type)
            .edited(fixArray)
            .filter { typeInfo in
                !ParticularType(typeInfo.type).isPrimitive
            }
            .map { typeInfo in
                try Message(typeInfo: typeInfo)
            }
            .reduce(into: Set()) { result, value in
                result.insert(value)
            }
            .forEach { element in
                self.messages.insert(element)
            }
    }
}

// MARK: - Private

private extension Tree {
    static func make<T>(_ type: T.Type) throws -> Tree<TypeInfo> {
        Node(try typeInfo(of: type)) { typeInfo in
            typeInfo.properties.compactMap {
                do {
                    return try Runtime.typeInfo(of: $0.type)
                } catch {
                    print(error)
                    return nil
                }
            }
        }
    }
}

private extension Message {
    static let void = Message(name: "VoidMessage", properties: [])
}
