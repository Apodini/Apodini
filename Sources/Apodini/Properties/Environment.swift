/// A property wrapper to inject pre-defined values  to a `Component`.
@propertyWrapper
public struct Environment<K: KeyChain, Value>: Property {
    /// Keypath to access an `EnvironmentValue`.
    internal var keyPath: KeyPath<K, Value>
    internal var dynamicValues: [KeyPath<K, Value>: Any] = [:]
    // swiftlint:disable force_unwrapping
    private var app = AppStorage.app!
    
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
        if let key = keyPath as? KeyPath<Application, Value> {
            return app[keyPath: key]
        }
        if let value = app.storage[keyPath] {
            return value
        }
        fatalError("Key path not found")
    }

    /// Sets the value for the given KeyPath.
    mutating func setValue(_ value: Value, for keyPath: WritableKeyPath<K, Value>) {
        self.dynamicValues[keyPath] = value
    }
}

/// `Application` storage.
public enum AppStorage {
    /// Holds the `Application` instance of the web service.
    public static var app: Application?
}

/// A protocol to define key paths that can be used with `@Environment` to retrieve pre-defined objects.
public protocol KeyChain { }

extension Application: KeyChain { }
