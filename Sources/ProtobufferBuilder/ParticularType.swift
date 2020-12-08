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
internal struct ParticularType {
    private let type: Any.Type
    
    init(_ type: Any.Type) {
        self.type = type
    }
}

extension ParticularType: CustomStringConvertible {
    var description: String {
        String("\(type)".prefix { $0 != "<" })
    }
    
    var isArray: Bool {
        description == "Array"
    }
}

extension ParticularType: Equatable {
    static func == (lhs: ParticularType, rhs: ParticularType) -> Bool {
        lhs.description == rhs.description
    }
    
    var isPrimitive: Bool {
        supportedScalarTypes
            .map(ParticularType.init)
            .contains(self)
    }
}

private let supportedScalarTypes: [Any.Type] = [
    Int32.self,
    Int64.self,
    UInt32.self,
    UInt64.self,
    Bool.self,
    String.self,
    Double.self,
    Float.self
]
