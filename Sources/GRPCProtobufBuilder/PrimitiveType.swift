//
//  File.swift
//  
//
//  Created by Nityananda on 30.11.20.
//

func isPrimitive(_ type: Any.Type) -> Bool {
    primitiveTypes
        .map(Type.init(type:))
        .contains(Type(type: type))
}

func isTopLevelCompatible(_ type: Any.Type) -> Bool {
    !isPrimitive(type)
}

private let primitiveTypes: [Any.Type] = [
    Bool.self,
    Int.self,
    // ...more Ints
    String.self,
    Array<Any>.self,
]

// MARK: - Type

private struct Type<T> {
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
