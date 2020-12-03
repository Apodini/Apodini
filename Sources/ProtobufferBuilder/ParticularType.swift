//
//  File.swift
//  
//
//  Created by Nityananda on 30.11.20.
//

import Runtime

// MARK: - Type

/// .
///
/// Particular: An antonym for generic.
internal struct ParticularType<T> {
    private let type: T
    
    init(_ type: T) {
        self.type = type
    }
}

extension ParticularType: CustomStringConvertible {
    var description: String {
        String("\(type)".prefix { $0 != "<" })
    }
}

extension ParticularType: Equatable {
    static func == (lhs: ParticularType<T>, rhs: ParticularType<T>) -> Bool {
        lhs.description == rhs.description
    }
}

// MARK: - Is Primitive

func isPrimitive(_ type: Any.Type) -> Bool {
    primitiveTypes
        .map(ParticularType.init)
        .contains(ParticularType(type))
}

private let primitiveTypes: [Any.Type] = [
    Bool.self,
    Int.self,
    // more numbers...
    String.self
]

// MARK: - Generic Name

func compatibleGenericName(_ typeInfo: TypeInfo) throws -> String {
    var tree: Tree = try Node(typeInfo) { typeInfo in
        try typeInfo.genericTypes.map { element in
            try Runtime.typeInfo(of: element)
        }
    }
    
    // Hacky...
    if typeInfo.isArray {
        tree = tree?.children.first
    }
    
    let name = tree
        .map { typeInfo in
            ParticularType(typeInfo.type)
        }
        .reduce(into: "") { (result, value) in
            let next = value.description
            result += result.isEmpty
                ? next
                : "Of\(next)"
        }
    
    return name
}
