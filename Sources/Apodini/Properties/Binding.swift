//
//  Binding.swift
//
//
//  Created by Max Obermeier on 23.02.21.
//

import Foundation
import ApodiniUtils

/// A `Binding` which may identify an `@Parameter`.
private protocol PotentiallyParameterIdentifyingBinding {
    /// The parameter's value
    var parameterId: UUID? { get }
}


extension _Internal {
    /// :nodoc:
    public static func getParameterId(ofBinding value: Any) -> UUID? {
        (value as? PotentiallyParameterIdentifyingBinding)?.parameterId
    }
}

/// A `Property` that can be used on `Handler`s for better re-usability. Depending on
/// the context the `Binding` can be bound to a `Binding.constant`, an `@Parameter`,
/// or an `@Environment`. The latter `Binding`s for the latter two are contained in their
/// `projectedValue`s.
@propertyWrapper
public struct Binding<Value>: DynamicProperty, PotentiallyParameterIdentifyingBinding {
    private var store: Properties
    
    private var config: Configuration {
        guard let config = store.wrappedValue["config"] as? Configuration else {
            print(store)
            fatalError("Could not find Configuration in store. The internal logic of Binding is broken!")
        }
        return config
    }
    
    var parameterId: UUID? {
        config.parameterId
    }
    
    public var wrappedValue: Value {
        let config = config
        
        if let `override` = config.override?.value {
            return `override`
        }
        
        return config.retriever(store)
    }
    
    public var projectedValue: Self {
        get {
            self
        }
        set {
            self = newValue
        }
    }
}

// MARK: Override

extension Binding {
    fileprivate struct Configuration: Property, InstanceCodable {
        var override: Box<Value?>?
        let retriever: (Properties) -> Value
        let parameterId: UUID?
    }
}

extension Binding.Configuration: Activatable {
    mutating func activate() {
        self.override = Box(nil)
    }
}

extension Binding {
    func override(with value: Value) {
        guard let box = config.override else {
            fatalError("Binding was overridden before it was activated.")
        }
        box.value = value
    }
}


// MARK: PathComponent

extension Binding: PathComponent & _PathComponent where Value: Codable {
    func append<Parser: PathComponentParser>(to parser: inout Parser) {
        guard let parameter = store.wrappedValue["parameter"] as? Parameter<Value> else {
            preconditionFailure("Only bindings created from a `Parameter` or `PathParameter` can be used as a path component")
        }
        
        parser.visit(parameter)
    }
}


// MARK: Constant

extension Binding {
    private init(constant: Value) {
        store = Properties()
            .with(Configuration(retriever: { _ in constant}, parameterId: nil), named: "config")
    }
    
    /// Create a `Binding` that always returns the given `value`.
    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(constant: value)
    }
    
    public init(wrappedValue value: Value) {
        self.init(constant: value)
    }
}


// MARK: Environment

extension Binding {
    private init<K: EnvironmentAccessible>(environment: Environment<K, Value>) {
        store = Properties()
            .with(Configuration(retriever: { store in
                guard let parameter = store.wrappedValue["environment"] as? Environment<K, Value> else {
                    fatalError("Could not find Environment in store. The internal logic of Binding is broken!")
                }
                return parameter.wrappedValue
            }, parameterId: nil), named: "config")
            .with(environment, named: "environment")
    }

    internal static func environment<K: EnvironmentAccessible>(_ environment: Environment<K, Value>) -> Binding<Value> {
        Binding(environment: environment)
    }
}

// MARK: EnvironmentObject

extension Binding {
    private init(environmentobject: EnvironmentObject<Value>) {
        store = Properties()
            .with(Configuration(retriever: { store in
                guard let parameter = store.wrappedValue["environmentobject"] as? EnvironmentObject<Value> else {
                    fatalError("Could not find EnvironmentObject in store. The internal logic of Binding is broken!")
                }
                return parameter.wrappedValue
            }, parameterId: nil), named: "config")
            .with(environmentobject, named: "environmentobject")
    }

    internal static func environmentObject(_ environment: EnvironmentObject<Value>) -> Binding<Value> {
        Binding(environmentobject: environment)
    }
}


// MARK: Parameter

extension Binding where Value: Codable {
    private init(parameter: Parameter<Value>) {
        store = Properties(namingStrategy: { names in
            names.count >= 3 ? names[names.count - 3] : nil
        })
            .with(Configuration(retriever: { store in
                guard let parameter = store.wrappedValue["parameter"] as? Parameter<Value> else {
                    fatalError("Could not find Parameter object in store. The internal logic of Binding is broken!")
                }
                return parameter.wrappedValue
            }, parameterId: parameter.id), named: "config")
            .with(parameter, named: "parameter")
    }
    
    internal static func parameter(_ parameter: Parameter<Value>) -> Binding<Value> {
        Binding(parameter: parameter)
    }
}


// MARK: Optional Wrapping

extension Binding {
    /// Creates a binding by projecting the base value to an optional value.
    public init<V>(_ base: Binding<V>) where Value == V? {
        let oldConfig = base.config
        store = base.store.with(Self.Configuration(retriever: { properties -> Value in
            oldConfig.retriever(properties)
        }, parameterId: oldConfig.parameterId), named: "config")
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
