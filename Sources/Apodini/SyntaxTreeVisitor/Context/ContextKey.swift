//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// A `OptionalContextKey` serves as a key definition for a `ContextNode`.
/// Optionally it can serve a reduction logic when inserting a new value into the `ContextNode`,
/// see `OptionalContextKey.reduce(...)`.
/// The `OptionalContextKey` is optional in the sense that it doesn't provide a default value, meaning
/// it may not exist on the `Context` for a given `Handler`.

public protocol OptionalContextKey {
    /// The type of the value the `OptionalContextKey` identifies. The value MUST NOT be of type `Optional`.
    associatedtype Value

    /// This function can be optionally implemented to provide a reduction logic when inserting a new
    /// value into a `ContextNode`.
    ///
    /// There are the following two default implementations - depending on the type - if no custom logic is specified:
    /// - The value with higher precedence overwrites the previous value
    /// - The value with higher precedence will be appended to the previous value for `Array` based ContextKeys
    ///
    /// For `ContextKey`s with default value, the default value won't ever be passed to the `reduce(...)` function.
    ///
    /// - Parameters:
    ///   - value: The current value of the context key.
    ///         The result of the reduction must be written into this inout parameter.
    ///   - nextValue: The return value of the provided closure is the newly inserted value.
    static func reduce(value: inout Self.Value, nextValue: Self.Value)
}

public extension OptionalContextKey {
    /// Default reduction logic. Completely replaces the current value with the next value.
    static func reduce(value: inout Self.Value, nextValue: Self.Value) {
        value = nextValue
    }
}

public extension OptionalContextKey where Value: AnyArray {
    /// Default reduction logic for array based `ContextKey`s.
    /// Joins the contents of the collections my appending the next value to the current value.
    static func reduce(value: inout Self.Value, nextValue: Self.Value) {
        value.append(contentsOf: nextValue)
    }
}


/// A `ContextKey` is a `OptionalContextKey` with the addition of the definition of a default value.
/// See implications of the reduction logic `OptionalContextKey.reduce(...)`.
public protocol ContextKey: OptionalContextKey {
    /// The default value this `ContextKey` provides.
    static var defaultValue: Self.Value { get }
}
