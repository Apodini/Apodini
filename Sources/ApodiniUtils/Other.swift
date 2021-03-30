//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 16.02.21.
//

import Foundation

/// The `Box` type can be used to wrap an object in a class
public class Box<T> {
    /// The value stored by the `Box`
    public var value: T

    /// Creates a new box filled with the specified value, and,
    /// if `T` has reference semantics, establishing a strong reference to it.
    public init(_ value: T) {
        self.value = value
    }
}

/// A weak reference to an object of class type
public struct Weak<T: AnyObject> {
    /// The value stored by the `Box`
    public weak var value: T?

    /// Creates a new box filled with the specified value, establishing a weak reference.
    public init(_ value: T) {
        self.value = value
    }
}

// MARK: Type-casting

/// Perform a dynamic cast from one type to another.
/// - returns: the casted value, or `nil` if the cast failed
/// - note: This is semantically equivalent to the `as?` operator.
///         The reason this function exists is to enable casting from `Any` to an optional type,
///         which is otherwise rejected by the type checker.
public func dynamicCast<U>(_ value: Any, to _: U.Type) -> U? {
    value as? U
}

/// Unsafely cast a value to a type.
/// - parameter value: The to-be-cast value
/// - parameter to: The to-be-casted-to type
/// - Note: This function will result in a fatal error if `value` cannot be cast to `T`.
///         Only use this function if you are fine with the program crashing as a result of the cast failing.
///         This function should only be used if you know *for a fact* that `value` is nonnil, and can be cast to `T`.
public func unsafelyCast<T>(_ value: Any, to _: T.Type) -> T {
    if let typed = value as? T {
        return typed
    } else {
        fatalError("Unable to cast value of type '\(type(of: value))' to type '\(T.self)'")
    }
}
