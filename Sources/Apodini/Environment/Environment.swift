@_implementationOnly import Runtime

/// A key for accessing values in the environment.
public protocol EnvironmentKey {
    /// Represents the type of the environment key’s value.
    associatedtype Value
    /// The default value of the `EnvironmentKey`.
    static var defaultValue: Self.Value { get }
}

/// A collection of environment values.
/// Custom environment values can be created by extending this struct with new properties.
public struct EnvironmentValues {
    /// Singleton of `EnvironmentValues`.
    internal static var shared = EnvironmentValues()

    /// Dictionary of stored environment values.
    internal var values: [ObjectIdentifier: Any] = [:]

    /// Initializer of `EnvironmentValues`.
    init() { }

    /// Accesses the environment value associated with a custom key conforming to `EnvironmentKey`.
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
    
    /// Accesses the environment value associated with a custom key of type Application.
    public subscript<T>(keyPath: KeyPath<Application, T>) -> T {
        if let app = values[ObjectIdentifier(Application.Type.self)] as? Application {
            return app[keyPath: keyPath]
        }
        fatalError("Key path not found. The web service wasn't setup correctly")
    }
    
    /// Accesses the environment value associated with a custom key.
    public subscript<K, T>(keyPath: KeyPath<K, T>) -> T {
        if let value = values[ObjectIdentifier(keyPath)] as? T {
            return value
        }
        fatalError("Key path not found")
    }
}

/// A property wrapper to inject pre-defined values  to a `Component`.
@propertyWrapper
public struct Environment<K: KeyChain, Value>: Property {
    /// Keypath to access an `EnvironmentValue`.
    internal var keyPath: KeyPath<K, Value>
    internal var dynamicValues: [KeyPath<K, Value>: Any] = [:]
  
    /// Initializer of `Environment` specifically for `EnvironmentValues` for less verbose syntax.
    public init(_ keyPath: KeyPath<K, Value>) where K == EnvironmentValues {
        self.keyPath = keyPath
    }
    
    /// Initializer of `Environment` specifically for `Application` for less verbose syntax.
    public init(_ keyPath: KeyPath<K, Value>) where K == Application {
        self.keyPath = keyPath
    }
    
    /// Initializer of `Environment` for key paths conforming to `KeyChain`.
    public init(_ keyPath: KeyPath<K, Value>) {
        self.keyPath = keyPath
    }
    
    /// The current value of the environment property.
    public var wrappedValue: Value {
        if let value = dynamicValues[keyPath] as? Value {
            return value
        }
        if let key = keyPath as? KeyPath<EnvironmentValues, Value> {
            return EnvironmentValues.shared[keyPath: key]
        }
        if let key = keyPath as? KeyPath<Application, Value> {
            return EnvironmentValues.shared[key]
        }
        return EnvironmentValues.shared[keyPath]
    }

    /// Sets the value for the given KeyPath.
    mutating func setValue(_ value: Value, for keyPath: WritableKeyPath<K, Value>) {
        self.dynamicValues[keyPath] = value
    }
}

/// Helper struct to add objects to `EnvironmentValues`.
public struct EnvironmentValue<K: KeyChain, Value> {
    /// Initiliazer of `EnvironmentValue`.
    /// Adds key path with value to `EnvironmentValues`.
    @discardableResult
    public init(_ keyPath: KeyPath<K, Value>, _ value: Value) {
        EnvironmentValues.shared.values[ObjectIdentifier(keyPath)] = value
    }
}

/// A protocol to define key paths that can be used with `@Environment` to retrieve pre-defined objects.
public protocol KeyChain { }

extension EnvironmentValues: KeyChain { }

extension Application: KeyChain { }
