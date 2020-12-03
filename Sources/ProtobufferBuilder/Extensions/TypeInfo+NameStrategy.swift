//
//  File.swift
//  
//
//  Created by Nityananda on 03.12.20.
//

import Runtime

extension Kind {
    var nameStrategy: (TypeInfo) throws -> String {
        switch self {
        case .struct, .class:
            return compatibleGenericName
        case .tuple:
            return Self.tuple
        default:
            return { _ in throw Exception(message: "Kind: \(self) is not supported.") }
        }
    }
    
    static func tuple(typeInfo: TypeInfo) throws -> String {
        if typeInfo.type == Void.self {
            return "Void"
        } else {
            throw Exception(message: "Tuple: \(typeInfo.type) is not supported.")
        }
    }
}

