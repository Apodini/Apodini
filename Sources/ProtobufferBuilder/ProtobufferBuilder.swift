//
//  File.swift
//
//
//  Created by Nityananda on 26.11.20.
//

import Runtime

public class ProtobufferBuilder {
    private var messages: Set<Message>
    private var services: Set<Service>
    
    public init() {
        self.messages = Set()
        self.services = Set()
    }
}

public extension ProtobufferBuilder {
    func addService<T>(of type: T.Type = T.self) throws {
        print(type)
    }
    
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
                !isPrimitive(typeInfo.type)
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
        messages
            .sorted(by: \.name)
            .map(\.description)
            .joined(separator: "\n\n")
    }
}
