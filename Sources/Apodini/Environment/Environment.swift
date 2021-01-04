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
public struct Environment<K: ApodiniKeys, Value>: Property {
    /// Keypath to access an `EnvironmentValue`.
    internal var keyPath: KeyPath<K, Value>
    internal var dynamicValues: [ObjectIdentifier: Any] = [:]
    
    /// Initializer of `Environment` for `EnvironmentValues`.
    public init(_ keyPath: KeyPath<K, Value>) where K == EnvironmentValues {
        self.keyPath = keyPath
    }
    
    /// Initializer of `Environment` for key paths conforming to `ApodiniKeys`.
    public init(_ keyPath: KeyPath<K, Value>) {
        self.keyPath = keyPath
    }
    
    /// The current value of the environment property.
    public var wrappedValue: Value {
        if let value = dynamicValues[ObjectIdentifier(keyPath)] as? Value {
            return value
        }
        if let key = keyPath as? KeyPath<EnvironmentValues, Value> {
            return EnvironmentValues.shared[keyPath: key]
        }
        return EnvironmentValues.shared[keyPath]
    }

    /// Sets the value for the given KeyPath.
    mutating func setValue(_ value: Value, for keyPath: WritableKeyPath<EnvironmentValues, Value>) {
        self.dynamicValues[ObjectIdentifier(keyPath)] = value
    }
}

extension Component {
    /// Sets the value for the given key-path
    /// on properties of this `Component`
    /// annotated with `@Environment`.
    func withEnvironment<Value>(_ value: Value, for keyPath: WritableKeyPath<EnvironmentValues, Value>) -> Self {
        var selfRef = self
        do {
            let info = try typeInfo(of: type(of: self))

            for property in info.properties {
                if var child = (try property.get(from: selfRef)) as? Environment<EnvironmentValues, Value> {
                    child.setValue(value, for: keyPath)
                    try property.set(value: child, on: &selfRef)
                }
            }
        } catch {
            print(error)
        }
        return selfRef
    }
}

/// A protocol to define key paths that can be used with `@Environment` to retrieve pre-defined objects.
public protocol ApodiniKeys { }

extension EnvironmentValues: ApodiniKeys { }
