/// A property wrapper to inject pre-defined values  to a `Component`.
@propertyWrapper
public struct Environment<K: KeyChain, Value>: Property {
    /// Keypath to access an `EnvironmentValue`.
    internal var keyPath: KeyPath<K, Value>
    internal var dynamicValues: [KeyPath<K, Value>: Any] = [:]

    private var app: Application?
    /// `@Environment` can only be accessed from a `Request`.
    private var canAccess = false
    
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
        guard let app = app else {
            fatalError("The Application instance wasn't injected correctly.")
        }
        guard canAccess else {
            fatalError("The wrapped value was accessed before it was activated.")
        }
        
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

extension Environment: ApplicationInjectable {
    public mutating func inject(app: Application) {
        self.app = app
    }
}

extension Environment: Activatable {
    public mutating func activate() {
        canAccess = true
    }
}

/// A protocol to define key paths that can be used with `@Environment` to retrieve pre-defined objects.
public protocol KeyChain { }

extension Application: KeyChain { }
