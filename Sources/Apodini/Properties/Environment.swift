import ApodiniUtils

/// A property wrapper to inject pre-defined values  to a `Component`.
@propertyWrapper
public struct Environment<K: EnvironmentAccessible, Value>: Property {
    /// Keypath to access an `EnvironmentValue`.
    internal var keyPath: KeyPath<K, Value>
    internal var storage: Box<[KeyPath<K, Value>: Any]>?
    private var dynamicValues = [KeyPath<K, Value>: Any]()

    private var app: Application?
    
    /// Initializer of `Environment` specifically for `Application` for less verbose syntax.
    public init(_ keyPath: KeyPath<K, Value>) where K == Application {
        self.keyPath = keyPath
    }
    
    /// Initializer of `Environment` for key paths conforming to `EnvironmentAccessible`.
    public init(_ keyPath: KeyPath<K, Value>) {
        self.keyPath = keyPath
    }
    
    /// The current value of the environment property.
    public var wrappedValue: Value {
        guard let app = app else {
            fatalError("The Application instance wasn't injected correctly.")
        }
        guard let dynamicValues = storage else {
            fatalError("The wrapped value was accessed before it was activated.")
        }
        
        if let value = dynamicValues.value[keyPath] as? Value, dynamicValues.value[keyPath] != nil {
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
    
    /// A `Binding` that reflects this `Environment`.
    public var projectedValue: Binding<Value> {
        Binding.environment(self)
    }

    /// Sets the value for the given KeyPath.
    mutating func prepareValue(_ value: Value, for keyPath: WritableKeyPath<K, Value>) {
        dynamicValues[keyPath] = value
    }
    
    /// Sets the value for the given KeyPath for an **activated** Environment.
    func setValue(_ value: Value, for keyPath: WritableKeyPath<K, Value>) {
        guard let dynamicValues = storage else {
            fatalError("The wrapped value was accessed before it was activated.")
        }
        dynamicValues.value[keyPath] = value
    }
}

extension Environment: ApplicationInjectable {
    mutating func inject(app: Application) {
        self.app = app
    }
}

extension Environment: Activatable {
    mutating func activate() {
        storage = Box(self.dynamicValues)
    }
}

/// Properties that need an `Application` instance.
protocol ApplicationInjectable {
    /// injects an `Application` instance
    mutating func inject(app: Application)
}

/// A protocol to define key paths that can be used with `@Environment` to retrieve pre-defined objects.
public protocol EnvironmentAccessible { }

extension Application: EnvironmentAccessible { }
