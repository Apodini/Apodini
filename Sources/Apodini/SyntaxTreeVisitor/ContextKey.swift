//
//  ContextKey.swift
//  
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

/// A `OptionalContextKey` context key TODO document
protocol OptionalContextKey {
    associatedtype Value

    static func reduce(value: inout Self.Value, nextValue: () -> Self.Value)
}

extension OptionalContextKey {
    static func reduce(value: inout Self.Value, nextValue: () -> Self.Value) {
        value = nextValue()
    }
}


// TODO document
protocol ContextKey: OptionalContextKey {
    associatedtype DefaultValue

    static var defaultValue: DefaultValue { get }
}

extension ContextKey {
    // I know the compiler creates a warning about this, but using it as a type constraint isn't actually the same thing
    typealias Value = DefaultValue
}

extension ContextKey {
    static func reduce(value: inout Self.Value, nextValue: () -> Self.Value) {
        value = nextValue()
    }
}
