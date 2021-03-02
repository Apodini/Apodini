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
    public init<V>(_ base: Binding<V>) where Value == V? {
        self.store = base.store
        switch base.retrieval {
        case .constant(let value):
            self.retrieval = .constant(value)
        case .storage(let retriever):
            self.retrieval = .storage(retriever)
        }
    }
    
    /// Creates a binding by projecting this binding's value to an optional value.
    public var asOptional: Binding<Value?> {
        Binding<Value?>(self)
    }
    
    /// Create an optional, always present `Binding` that always returns the given `value`.
    /// - Note: In most cases you will be able to also use `Binding.constant(value)`, this
    ///         just puts more emphasis on the semantics of optional-wrapping.
    public static func some<V>(_ value: V) -> Binding<V?> {
        Binding<V?>(constant: value)
    }
}


// MARK: Convenience Literal-Initializers

extension Binding: ExpressibleByNilLiteral where Value: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(constant: nil)
    }
}

extension Binding: ExpressibleByStringLiteral,
                   ExpressibleByUnicodeScalarLiteral,
                   ExpressibleByExtendedGraphemeClusterLiteral
where Value: ExpressibleByStringLiteral,
      Value.StringLiteralType == Value.UnicodeScalarLiteralType,
      Value.StringLiteralType == Value.ExtendedGraphemeClusterLiteralType {
    public typealias UnicodeScalarLiteralType = Value.StringLiteralType
    
    public typealias ExtendedGraphemeClusterLiteralType = Value.StringLiteralType
    
    public init(stringLiteral value: Value.StringLiteralType) {
        self.init(constant: Value(stringLiteral: value))
    }
}

extension Binding: ExpressibleByStringInterpolation
where Value: ExpressibleByStringInterpolation,
      Value.StringLiteralType == DefaultStringInterpolation.StringLiteralType,
      Value.StringLiteralType == Value.UnicodeScalarLiteralType,
      Value.StringLiteralType == Value.ExtendedGraphemeClusterLiteralType { }

extension Binding: ExpressibleByBooleanLiteral where Value: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Value.BooleanLiteralType) {
        self.init(constant: Value(booleanLiteral: value))
    }
}

extension Binding: ExpressibleByFloatLiteral where Value: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Value.FloatLiteralType) {
        self.init(constant: Value(floatLiteral: value))
    }
}

extension Binding: ExpressibleByIntegerLiteral where Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Value.IntegerLiteralType) {
        self.init(constant: Value(integerLiteral: value))
    }
}

/// `ExpressibleByCollection` is an quivalent to `ExpressibleByArrayLiteral` except its
/// initializer doesn't take the element-sequence, but a collection. This allows for implementing
/// `ExpressibleByArrayLiteral` for types that expose the resulting collection type without
/// constraining the conformance to a single implementation, e.g. using `Array` instead of `Set`.
public protocol ExpressibleByCollection {
    /// The type can be instantiated from `Collection`s of member-type `Element`.
    associatedtype Element
    
    /// Create a new instance from the given collection.
    init<C: Collection>(collection: C) where C.Element == Element
}

extension Array: ExpressibleByCollection {
    public typealias Element = Element
    
    public init<C: Collection>(collection: C) where C.Element == Element {
        if let array = collection as? Self {
            self = array
        } else {
            self.init()
            for elem in collection {
                self.append(elem)
            }
        }
    }
}

extension Set: ExpressibleByCollection {
    public typealias Element = Element
    
    public init<C: Collection>(collection: C) where C.Element == Element {
        if let set = collection as? Self {
            self = set
        } else {
            self.init()
            for elem in collection {
                self.insert(elem)
            }
        }
    }
}

extension Binding: ExpressibleByArrayLiteral where Value: ExpressibleByCollection {
    public init(arrayLiteral elements: Value.Element...) {
        self.init(constant: Value(collection: elements))
    }
}