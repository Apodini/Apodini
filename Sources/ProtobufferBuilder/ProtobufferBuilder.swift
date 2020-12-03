//
//  File.swift
//
//
//  Created by Nityananda on 26.11.20.
//

import Runtime

public class ProtobufferBuilder {
    private var messages: Set<Message> = .init()
    private var services: Set<Service> = .init()
    
    public init() {}
}

public extension ProtobufferBuilder {
    func add<T>(_ messageType: T.Type = T.self) throws {
        let tree: Tree = Node(try typeInfo(of: messageType)) { typeInfo in
            typeInfo.properties.compactMap {
                do {
                    return try Runtime.typeInfo(of: $0.type)
                } catch {
                    print(error)
                    return nil
                }
            }
        }
        
        let messages = try tree
            .edited(fixArray)
            .filter { typeInfo in
                !isPrimitive(typeInfo.type)
            }
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
