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
    supportedPrimitiveTypes
        .map(ParticularType.init)
        .contains(ParticularType(type))
}

private let supportedPrimitiveTypes: [Any.Type] = [
    Int32.self,
    Int64.self,
    UInt32.self,
    UInt64.self,
    Bool.self,
    String.self,
    Double.self,
    Float.self,
]
