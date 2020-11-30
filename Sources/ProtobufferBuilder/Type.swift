//
//  File.swift
//  
//
//  Created by Nityananda on 30.11.20.
//

import Runtime

// MARK: - Type

internal struct Type<T> {
    let type: T
}

extension Type: CustomStringConvertible {
    var description: String {
        String("\(type)".prefix { $0 != "<" })
    }
}

extension Type: Equatable {
    static func == (lhs: Type<T>, rhs: Type<T>) -> Bool {
        lhs.description == rhs.description
    }
}

// MARK: - Is Primitive

func isPrimitive(_ type: Any.Type) -> Bool {
    primitiveTypes
        .map(Type.init(type:))
        .contains(Type(type: type))
}

private let primitiveTypes: [Any.Type] = [
    Bool.self,
    Int.self,
    // ...more Ints
    String.self
]

// MARK: - Generic Name

func compatibleGenericName(_ typeInfo: TypeInfo) throws -> String {
    let tree: Tree = try Node(typeInfo) { typeInfo in
        try typeInfo.genericTypes.map { element in
            try Runtime.typeInfo(of: element)
        }
    }
    
    let name = tree
        .map { typeInfo in
            Type(type: typeInfo.type)
        }
        .reduce(into: "") { (result, value) in
            let next = value.description
            result += result.isEmpty
                ? next
                : "Of\(next)"
        }
    
    return name
}
