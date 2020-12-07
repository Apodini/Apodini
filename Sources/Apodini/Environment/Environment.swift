/// A key for accessing values in the environment.
public protocol EnvironmentKey {
    /// Represents the type of the environment key’s value.
    associatedtype Value
    /// The default value of the `EnvironmentKey`
    static var defaultValue: Self.Value { get }
}

/// A collection of environment values.
/// Custom environment values can be created by extending this struct with new properties.
public struct EnvironmentValues {
    var values: [ObjectIdentifier: Any] = [:]
    
    public init() { }
    
    /// Accesses the environment value associated with a custom key.
    public subscript<K>(key: K.Type) -> K.Value where K: EnvironmentKey {
        get {
            if let value = values[ObjectIdentifier(key)] as? K.Value {
                return value
            }
            return K.defaultValue
        }
        set {
            values[ObjectIdentifier(key)] = newValue
        }
    }
    
    /// Represents contents of the environment values instance.
    public var description: String {
        ""
    }
}

protocol DynamicProperty { }

/// A property wrapper to inject pre-defined values  to a `Component`.
@propertyWrapper
public struct Environment<Value>: DynamicProperty {
    internal enum Content {
        case keyPath(KeyPath<EnvironmentValues, Value>)
        case value(Value)
    }
    
    internal var content: Environment<Value>.Content
    
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        content = .keyPath(keyPath)
    }
    
    public var wrappedValue: Value {
        switch content {
        case let .value(value):
            return value
        case let .keyPath(keyPath):
            // not bound to a view, return the default value
            return EnvironmentValues()[keyPath: keyPath]
        }
    }
}
