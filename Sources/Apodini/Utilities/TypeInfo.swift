//
//  TypeInfo.swift
//  
//
//  Created by Paul Schmiedmayer on 1/13/21.
//

import Foundation
@_implementationOnly import Runtime


// MARK: - Mangled Name
func mangledName(of type: Any.Type) -> String {
    do {
        let typeInfo = try Runtime.typeInfo(of: type)
        return typeInfo.mangledName
    } catch {
        return "\(type)"
    }
}


// MARK: - Optional
func isOptional(_ type: Any.Type) -> Bool {
    do {
        let typeInfo = try Runtime.typeInfo(of: type)
        return typeInfo.kind == .optional
    } catch {
        // typeInfo(of:) only throws if the `Kind` enum isn't one of the supported cases:
        //  .struct, .class, .existential, .tuple, .enum, .optional.
        // Thus if it throws, we know for sure that it isn't a optional.
        return false
    }
}

// MARK: - Enum
func isEnum(_ type: Any.Type) -> Bool {
    do {
        let typeInfo = try Runtime.typeInfo(of: type)
        return typeInfo.kind == .enum
    } catch {
        return false
    }
}


// MARK: - Supported Scalar Types
private let supportedScalarTypes: Set<ObjectIdentifier> = [
    ObjectIdentifier(Int.self),
    ObjectIdentifier(Int32.self),
    ObjectIdentifier(Int64.self),
    ObjectIdentifier(UInt.self),
    ObjectIdentifier(UInt32.self),
    ObjectIdentifier(UInt64.self),
    ObjectIdentifier(Bool.self),
    ObjectIdentifier(String.self),
    ObjectIdentifier(Double.self),
    ObjectIdentifier(Float.self)
]

func isSupportedScalarType(_ type: Any.Type) -> Bool {
    supportedScalarTypes
        .contains(ObjectIdentifier(type))
}

func isAmbiguousSupportedFixedWidthInteger(_ type: Any.Type) -> Bool {
    let types = [
        ObjectIdentifier(Int.self),
        ObjectIdentifier(UInt.self),
    ]
    
    precondition(supportedScalarTypes.isSuperset(of: types))
    
    return types.contains(ObjectIdentifier(type))
}
