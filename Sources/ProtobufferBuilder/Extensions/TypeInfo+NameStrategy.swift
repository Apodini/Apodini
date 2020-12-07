//
//  File.swift
//  
//
//  Created by Nityananda on 03.12.20.
//

import Runtime

extension TypeInfo {
    func compatibleName() throws -> String {
        switch kind {
        case .struct, .class:
            return try compatibleGenericName()
        case .tuple:
            return try tupleName()
        default:
            throw Exception(message: "Kind: \(kind) is not supported")
        }
    }
}

private extension TypeInfo {
    func compatibleGenericName() throws -> String {
        var tree: Tree = try Node(self) { typeInfo in
            try typeInfo.genericTypes.map { element in
                try Runtime.typeInfo(of: element)
            }
        }
        
        // Hacky...
        if isArray {
            tree = tree?.children.first
        }
        
        let name = tree
            .map { typeInfo in
                ParticularType(typeInfo.type)
            }
            .reduce(into: "") { result, value in
                let next = value.description
                result += result.isEmpty
                    ? next
                    : "Of\(next)"
            }
        
        return name
    }

    func tupleName() throws -> String {
        if type == Void.self {
            return "Void"
        } else {
            throw Exception(message: "Tuple: \(type) is not supported")
        }
    }
}
