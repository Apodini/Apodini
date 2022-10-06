//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
@_implementationOnly import Runtime


/// Returns the mangled name of a type
public func mangledName(of type: Any.Type) -> String {
    do {
        let typeInfo = try Runtime.typeInfo(of: type)
        return typeInfo.mangledName
    } catch {
        return "\(type)"
    }
}


/// Test whether a type is an `Optional`
public func isOptional(_ type: Any.Type) -> Bool {
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


/// Test whether a type is an enum
public func isEnum(_ type: Any.Type) -> Bool {
    do {
        let typeInfo = try Runtime.typeInfo(of: type)
        return typeInfo.kind == .enum
    } catch {
        return false
    }
}


private func isTypeOfKind<T>(_: T.Type, name: inout String, kind: Kind) -> Bool {
    guard let typeInfo = try? Runtime.typeInfo(of: T.self) else {
        fatalError("Unable to get type info for type '\(T.self)'")
    }

    name = typeInfo.name
    return typeInfo.kind == kind
}

/// Run a precondition check to make sure that a type is a struct
/// - parameter T: The type for which to assert that it is a struct
/// - parameter messagePrefix: An optional string which will be prefixed to the "T must be a struct" message
public func preconditionTypeIsStruct<T>(_: T.Type, messagePrefix: String? = nil) {
    var name: String = "DEFAULT"
    precondition(isTypeOfKind(T.self, name: &name, kind: .struct), "\(messagePrefix.map { $0 + " " } ?? "")'\(name)' must be a struct")
}

/// Run a assert check to make sure that a type is a struct
/// - parameter T: The type for which to assert that it is a struct
/// - parameter messagePrefix: An optional string which will be prefixed to the "T must be a struct" message
public func assertTypeIsStruct<T>(_: T.Type, messagePrefix: String? = nil) {
    var name: String = "DEFAULT"
    assert(isTypeOfKind(T.self, name: &name, kind: .struct), "\(messagePrefix.map { $0 + " " } ?? "")'\(name)' must be a struct")
}


/// Test whether a value is a `Sequence`
public func isSequence(_ value: Any) -> Bool {
    (value as? any Sequence) != nil
}


/// Test whether a value is a `Collection`
public func isCollection(_ value: Any) -> Bool {
    (value as? any Collection) != nil
}


// MARK: ObjectIdentifier/Any.Type Sequences

extension Set where Element == ObjectIdentifier {
    /// Creates a new `Set` from the specified types
    public init(_ types: Any.Type...) {
        self.init(types)
    }
    
    /// Creates a new `Set` from the specified types
    public init<S>(_ other: S) where S: Sequence, S.Element == Any.Type {
        self = Set(other.map { ObjectIdentifier($0) })
    }
}


extension Sequence where Element == ObjectIdentifier {
    /// Checks whether the sequence contains the specified type
    public func contains(_ other: Any.Type) -> Bool {
        contains(ObjectIdentifier(other))
    }
}


extension Sequence where Element == Any.Type {
    /// Checks whether the sequence contains the specified type
    public func contains(_ other: Any.Type) -> Bool {
        contains { ObjectIdentifier($0) == ObjectIdentifier(other) }
    }
}


extension Dictionary where Key == ObjectIdentifier {
    /// Accesses the element stored in the dictionary at the specified key.
    public subscript(key: Any.Type) -> Value? {
        get { self[ObjectIdentifier(key)] }
        set { self[ObjectIdentifier(key)] = newValue }
    }
}
