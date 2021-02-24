//
//  Binding.swift
//
//
//  Created by Max Obermeier on 23.02.21.
//

import Foundation

private enum Retrieval<Value> {
    case constant(Value)
    case storage((Properties) -> Value)
}

/// A `Property` that can be used on `Handler`s for better re-usability. Depending on
/// the context the `Binding` can be bound to a `Binding.constant`, an `@Parameter`,
/// or an `@Environment`. The latter `Binding`s for the latter two are contained in their
/// `projectedValue`s.
@propertyWrapper
public struct Binding<Value>: DynamicProperty {
    private let store: Properties
    private var retrieval: Retrieval<Value>
    
    public var wrappedValue: Value {
        switch self.retrieval {
        case .constant(let value):
            return value
        case .storage(let retriever):
            return retriever(store)
        }
    }
}

// MARK: Constant

extension Binding {
    private init(constant: Value) {
        self.store = Properties()
        self.retrieval = .constant(constant)
    }
    
    /// Create a `Binding` that always returns the given `value`.
    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(constant: value)
    }
}

// MARK: Environment

extension Binding {
    private init<K: EnvironmentAccessible>(environment: Environment<K, Value>) {
        self.store = Properties(wrappedValue: ["environment": environment])
        self.retrieval = .storage({ store in
            guard let parameter = store.wrappedValue["environment"] as? Environment<K, Value> else {
                fatalError("Could not find Environment object in store. The internal logic of Binding is broken!")
            }
            return parameter.wrappedValue
        })
    }
    
    internal static func environment<K: EnvironmentAccessible>(_ environment: Environment<K, Value>) -> Binding<Value> {
        Binding(environment: environment)
    }
}

// MARK: Parameter

extension Binding where Value: Codable {
    private init(parameter: Parameter<Value>) {
        self.store = Properties(wrappedValue: ["parameter": parameter], namingStrategy: { names in
            names[names.count - 3]
        })
        self.retrieval = .storage({ store in
            guard let parameter = store.wrappedValue["parameter"] as? Parameter<Value> else {
                fatalError("Could not find Parameter object in store. The internal logic of Binding is broken!")
            }
            return parameter.wrappedValue
        })
    }
    
    internal static func parameter(_ parameter: Parameter<Value>) -> Binding<Value> {
        Binding(parameter: parameter)
    }
}

// MARK: Optional Wrapping

extension Binding {
    /// Creates a binding by projecting the base value to an optional value.
    public init<V: Codable>(_ base: Binding<V>) where Value == V? {
        self.store = base.store
        switch base.retrieval {
        case .constant(let value):
            self.retrieval = .constant(value)
        case .storage(let retriever):
            self.retrieval = .storage(retriever)
        }
    }
}
