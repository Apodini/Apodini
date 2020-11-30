//
//  File.swift
//
//
//  Created by Nityananda on 26.11.20.
//

import Runtime

public class ProtobufferBuilder {
    private var messages: Set<GRPCMessage> = .init()
    private var services: Set<GRPCService> = .init()
    
    public init() {}
}

public extension ProtobufferBuilder {
    func add<T>(_ messageType: T.Type = T.self) throws {
        let tree: Tree = Node(try typeInfo(of: messageType), getChildren)
        #warning("TODO: Children...")
        let messages = try tree
            .contextMap { (node) in
                Node(value: try GRPCMessage(typeInfo: node), children: .init())
            }
            .reduce(into: Set()) { (result, value) in
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
            .map(\.description)
            .joined(separator: "\n")
    }
}

private func getChildren(_ typeInfo: TypeInfo) -> [TypeInfo] {
    typeInfo.properties.compactMap {
        do {
            return try Runtime.typeInfo(of: $0.type)
        } catch {
            print(error)
            return nil
        }
    }
}
