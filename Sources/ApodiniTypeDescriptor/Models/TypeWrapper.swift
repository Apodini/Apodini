//
//  File.swift
//  
//
//  Created by Eldi Cano on 12.04.21.
//

import Foundation
@_implementationOnly import Runtime

public enum TypeWrapper {
    case null
    case exactlyOne(Encodable.Type)
    case optional(Encodable.Type)
    case array(Encodable.Type)
    case dictionary(key: Encodable.Type, value: Encodable.Type)
}

extension TypeWrapper: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .null:
            return "null"
        case .exactlyOne(let type):
            return String(describing: type)
        case .optional(let type):
            return ".optional(\(String(describing: type)))"
        case .array(let type):
            return ".array(\(String(describing: type)))"
        case .dictionary(key: let key, value: let value):
            return ".dictionary(key: \(String(describing: key)), value: \(String(describing: value)))"
        }
    }
}

enum TypeWrapperError: Error {
    case error(_ message: String)
}

private func dictionary(of type: Encodable.Type) throws -> TypeWrapper {
    let typeInfo = try Runtime.typeInfo(of: type)
    
    guard
        let keyType = typeInfo.genericTypes.first as? Encodable.Type,
        let valueType = typeInfo.genericTypes.last as? Encodable.Type
    else { throw TypeWrapperError.error("Keys and Values of \(type) must conform to Encodable") }
    
    return .dictionary(key: keyType, value: valueType)
}

private func optional(of type: Encodable.Type) throws -> TypeWrapper {
    let typeInfo = try Runtime.typeInfo(of: type)
    
    guard let wrappedValueType = typeInfo.genericTypes.first as? Encodable.Type else {
        throw TypeWrapperError.error("Wrapped value of \(type) must conform to Encodable")
    }
    
    return .optional(wrappedValueType)
}

private func array(of type: Encodable.Type) throws -> TypeWrapper {
    let typeInfo = try Runtime.typeInfo(of: type)
    
    guard let keyType = typeInfo.genericTypes.first as? Encodable.Type else {
        throw TypeWrapperError.error("Elements of \(type) must conform to Encodable")
    }
    
    return .array(keyType)
}

func typeWrapper(for encodable: Encodable.Type) throws -> TypeWrapper {
    switch MangledName(encodable) {
    case .optional: return try optional(of: encodable)
    case .array: return try array(of: encodable)
    case .dictionary: return try dictionary(of: encodable)
    default: return .exactlyOne(encodable)
    }
}
