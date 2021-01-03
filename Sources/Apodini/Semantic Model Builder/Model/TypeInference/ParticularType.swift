//
//  File.swift
//
//
//  Created by Nityananda on 30.11.20.
//

import Foundation

/// `ParticularType` encapsulates functionality around specific types that may be generic,
/// or types that may be understood as _scalar_ or _primitive_.
///
/// Particular: An antonym for generic.
struct ParticularType {
    private let type: Any.Type

    init(_ type: Any.Type) {
        self.type = type
    }
}

// MARK: - ParticularType: CustomStringConvertible

extension ParticularType: CustomStringConvertible {
    var description: String {
        String("\(type)".prefix { $0 != "<" })
    }

    var isArray: Bool {
        description == "Array"
    }

    var isOptional: Bool {
        description == "Optional"
    }
}

// MARK: - ParticularType: Equatable

extension ParticularType: Equatable {
    static func == (lhs: ParticularType, rhs: ParticularType) -> Bool {
        lhs.description == rhs.description
    }

    var isPrimitive: Bool {
        supportedScalarTypes
                .map(ParticularType.init)
                .contains(self)
    }
    
    var isUUID: Bool {
        ParticularType.init(UUID.self) == self
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
