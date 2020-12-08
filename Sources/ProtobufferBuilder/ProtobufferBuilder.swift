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
    private var messages: Set<Message>
    private var services: Set<Service>
    
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
        print(type)
    }
    
    /// `addMessage` builds a Protobuffer message declaration from the type parameter.
    /// - Parameter type: the type of the message
    /// - Throws: `Error`s of type `Exception`
    func addMessage<T>(of type: T.Type = T.self) throws {
        print(type)
        
        let tree: Tree = Node(try typeInfo(of: type)) { typeInfo in
            typeInfo.properties.compactMap {
                do {
                    return try Runtime.typeInfo(of: $0.type)
                } catch {
                    print(error)
                    return nil
                }
            }
        }
        
        let modified = try tree
            .edited(fixArray)
            .filter { typeInfo in
                !ParticularType(typeInfo.type).isPrimitive
            }
        
        print(modified.isEmpty)
        
        let messages = try modified
            .map { typeInfo in
                try Message(typeInfo: typeInfo)
            }
            .reduce(into: Set()) { result, value in
                result.insert(value)
            }
        
        messages.forEach { element in
            self.messages.insert(element)
        }
    }
}

extension ProtobufferBuilder: CustomStringConvertible {
    public var description: String {
        let messages = self.messages
            .sorted(by: \.name)
            .map(\.description)
            .joined(separator: "\n\n")
        
        return """
            syntax = "proto3";

            \(messages)
            """
    }
}
