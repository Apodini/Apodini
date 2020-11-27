//
//  File.swift
//
//
//  Created by Nityananda on 26.11.20.
//

import Runtime

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

private func isNotPrimitive(_ typeInfo: TypeInfo) -> Bool {
    !["Int", "String", "Array"].contains {
        typeInfo.name.hasPrefix($0)
    }
}

public func code<T>(_ type: T.Type) throws {
    let tree: Tree = Node(try typeInfo(of: type), getChildren)
    let messages = try tree
        // Prune tree...
        .filter(isNotPrimitive)
        .reduce(into: Set()) { (result, value) in
            result.insert(value)
        }
        .map(GRPCMessage.init(typeInfo:))
    
    print("--------")
    print(
        messages
            .map(\.description)
            .joined(separator: "\n")
    )
    print("--------")
}
