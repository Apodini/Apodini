//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


/// A type whoch models an optional value.
public protocol AnyOptional {
    /// The type of the value wrapped by this optional type
    static var wrappedType: Any.Type { get }
    /// The type-erased value stored by this optional
    var typeErasedWrappedValue: Any? { get }
}

extension AnyOptional {
    /// The wrapped type
    public var wrappedType: Any.Type {
        Self.wrappedType
    }
}

extension Optional: AnyOptional {
    public static var wrappedType: Any.Type { Wrapped.self }
    public var typeErasedWrappedValue: Any? {
        switch self {
        case .some(let value):
            return .some(value)
        case .none:
            return .none
        }
    }
}


/// A protocol for identifying `Optional`s.
public protocol OptionalProtocol: AnyOptional {
    /// The underlying type of the Optional.
    associatedtype Wrapped
    // Disabling syntactic_sugar, improves readability and showcases what really happens here.
    // swiftlint:disable:next syntactic_sugar
    var optionalInstance: Optional<Wrapped> { get }
}


extension Optional: OptionalProtocol {
    // Disabling syntactic_sugar, improves readability and showcases what really happens here.
    // swiftlint:disable:next syntactic_sugar
    public var optionalInstance: Optional<Wrapped> { self }
}


/// Check whether `value` is some optional and is `nil`
public func isNil(_ value: Any) -> Bool {
    switch value {
    case Optional<Any>.none:
        return true
    default:
        return false
    }
}
