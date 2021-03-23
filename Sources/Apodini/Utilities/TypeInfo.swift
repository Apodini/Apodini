//
//  TypeInfo.swift
//  
//
//  Created by Paul Schmiedmayer on 1/13/21.
//


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


/// Whether the type is a supported scalar type
public func isSupportedScalarType(_ type: Any.Type) -> Bool {
    supportedScalarTypes.contains(ObjectIdentifier(type))
}
