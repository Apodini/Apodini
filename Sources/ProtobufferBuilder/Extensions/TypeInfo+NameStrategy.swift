//
//  File.swift
//  
//
//  Created by Nityananda on 03.12.20.
//

import Runtime

extension TypeInfo {
    func compatibleName() throws -> String {
        let type = ParticularType(self.type)
        
        if type.isPrimitive {
            return type.description.lowercased()
        } else {
            let result: String
            
            switch kind {
            case .struct, .class:
                result = try compatibleGenericName()
            case .tuple:
                result = try tupleName()
            default:
                throw Exception(message: "Kind: \(kind) is not supported")
            }
            
            return result
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
        
        if ParticularType(type).isArray {
            tree = tree?.children.first
        }
        
        let name = tree
            .map { typeInfo in
                ParticularType(typeInfo.type).description
            }
            .reduce(into: "") { result, next in
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
