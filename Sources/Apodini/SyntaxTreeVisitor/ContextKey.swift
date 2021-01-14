//
//  ContextKey.swift
//  
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

/// A `OptionalContextKey` serves as a key definition for a `ContextNode`.
/// Optionally it can serve a reduction logic when inserting a new value into the `ContextNode`,
/// see `OptionalContextKey.reduce(...)`.
/// The `OptionalContextKey` is optional in the sense that it doesn't provide a default value, meaning
/// it may not exists on the `Context` for a given `Handler`.
protocol OptionalContextKey {
    /// The type of the value the `OptionalContextKey` identifies. The value MUST NOT be of type `Optional`.
    associatedtype Value

    /// This function can be optionally implemented to provide a reduction logic when inserting a new
    /// value into a `ContextNode`. By default the previous value will just be overwritten.
    /// As `OptionalContextKey` do not provide a default value, `reduce(...)` will not be called on first
    /// insertion of a value for this `OptionalContextKey`.
    ///
    /// - Parameters:
    ///   - value: The current value of the context key.
    ///         The result of the reduction must be written into this inout parameter.
    ///   - nextValue: The return value of the provided closure is the newly inserted value.
    static func reduce(value: inout Self.Value, nextValue: () -> Self.Value)
}

extension OptionalContextKey {
    static func reduce(value: inout Self.Value, nextValue: () -> Self.Value) {
        value = nextValue()
    }
}


/// A `ContextKey` is a `OptionalContextKey` with the addition of the definition of a default value.
/// See implications of the reduction logic `OptionalContextKey.reduce(...)`.
protocol ContextKey: OptionalContextKey {
    /// The default value this `ContextKey` provides.
    static var defaultValue: Self.Value { get }
}
