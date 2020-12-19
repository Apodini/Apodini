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
    private init() { }
    
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
}

/// A property wrapper to inject pre-defined values  to a `Component`.
@propertyWrapper
public struct Environment<Value> {
    /// Keypath to access an `EnvironmentValue`.
    internal var keyPath: KeyPath<EnvironmentValues, Value>
    
    /// Initializer of `Environment`.
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.keyPath = keyPath
    }
    
    /// The current value of the environment property.
    public var wrappedValue: Value {
        EnvironmentValues.shared[keyPath: keyPath]
    }
}
