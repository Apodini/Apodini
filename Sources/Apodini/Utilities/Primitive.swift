//
//  TypeInfo.swift
//  
//
//  Created by Paul Schmiedmayer on 1/13/21.
//

import Foundation

/// A typealias of `Codable` & `Equatable` & `Hashable`
public typealias Value = Codable & Equatable & Hashable

/// Base helper protocol for primitive types
public protocol _Primitive {}

/// A protocol that all supported primitive / scalar types in Apodini conform to
public protocol Primitive: _Primitive, Value {}

// MARK: - Primitive Conformance
extension Int: Primitive {}
extension Int32: Primitive {}
extension Int64: Primitive {}
extension UInt: Primitive {}
extension UInt32: Primitive {}
extension UInt64: Primitive {}
extension Bool: Primitive {}
extension String: Primitive {}
extension Double: Primitive {}
extension Float: Primitive {}
extension UUID: Primitive {}

/// Whether the type is a supported scalar type
public func isSupportedScalarType(_ type: Any.Type) -> Bool {
    (type.self as? _Primitive.Type) != nil
}
