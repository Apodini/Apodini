//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import ApodiniUtils


/// A property wrapper to inject pre-defined values  to a ``Component``.
///
/// If `Value` is an ``ObservableObject``, ``Environment`` observes its value
/// just as ``ObservedObject``. Use ``Delegate/environment(_:_:)-mc6t`` to
///  inject a value locally, or define a global default using ``EnvironmentValue``
@propertyWrapper
public struct Environment<Key: EnvironmentAccessible, Value>: Property {
    private struct Storage {
        var changed: Bool
        weak var ownObservation: Observation?
        var childObservation: Observation?
        var count: UInt64 = 0
    }
    
    /// Keypath to access an `EnvironmentValue`.
    @Boxed internal var keyPath: KeyPath<Key, Value>?
    
    private var app: Application?
    
    // only used if Value is ObservableObject
    private var storage: Box<Storage>?
    @Boxed private var observe = false
    
    @LocalEnvironment private var localEnvironment: Value?
    
    /// Initializer of `Environment` specifically for `Application` for less verbose syntax.
    public init(_ keyPath: KeyPath<Key, Value>) where Key == Application {
        self.init(from: keyPath, observed: true)
    }
    
    /// Initializer of `Environment` for key paths conforming to `EnvironmentAccessible`.
    public init(_ keyPath: KeyPath<Key, Value>) {
        self.init(from: keyPath, observed: true)
    }
    
    /// Initializer of `Environment` specifically for `Application` for less verbose syntax.
    public init(_ keyPath: KeyPath<Key, Value>, observed: Bool) where Key == Application, Value: ObservableObject {
        self.init(from: keyPath, observed: observed)
    }
    
    /// Initializer of `Environment` for key paths conforming to `EnvironmentAccessible`.
    public init(_ keyPath: KeyPath<Key, Value>, observed: Bool) where Value: ObservableObject {
        self.init(from: keyPath, observed: observed)
    }
    
    private init(from keyPath: KeyPath<Key, Value>, observed: Bool) {
        self._localEnvironment = LocalEnvironment()
        self.keyPath = keyPath
        self.observe = observed
    }
    
    /// The current value of the environment property.
    public var wrappedValue: Value {
        if let value = localEnvironment {
            return value
        }
        
        guard let app = app else {
            fatalError("The Application instance wasn't injected correctly.")
        }
        
        if let key = keyPath as? KeyPath<Application, Value> {
            return app[keyPath: key]
        }
        if let key = keyPath, let value = app.storage[key] {
            return value
        }
        
        fatalError("Key path \(keyPath as Any) (kvcKeyPathString: \(keyPath?._kvcKeyPathString as Any)) not found")
    }
    
    /// A `Binding` that reflects this `Environment`.
    public var projectedValue: Binding<Value> {
        Binding.environment(self)
    }
    
    /// Sets the value for the given KeyPath.
    mutating func prepareValue(_ value: Value, for keyPath: WritableKeyPath<Key, Value>) {
        _localEnvironment.prepareValue(value)
    }
}

extension Environment: Decodable {
    public init(from decoder: any Decoder) throws {
        self._localEnvironment = LocalEnvironment()
        self.keyPath = nil
        self.observe = false
    }
}

/// Since ``Environment`` is now allowed in the ``WebService``, the property values have to be backed up and then restored since the ArgumentParser doesn't cache those values
extension Environment: ArgumentParserStoreable {
    public func store(in store: inout [String: any ArgumentParserStoreable], keyedBy key: String) {
        store[key] = self
    }
    
    public func restore(from store: [String: any ArgumentParserStoreable], keyedBy key: String) {
        if let storedValues = store[key] as? Environment {
            self.keyPath = storedValues.keyPath
            self.observe = storedValues.observe
            // No need to reinstanciate the local environment since it's already instenciated by the Decodable initializer
        } else {
            fatalError("Stored properties couldn't be read. Key=\(key)")
        }
    }
}


@propertyWrapper
struct LocalEnvironment<Value> {
    internal var storage: Box<Value?>?
    private var dynamicValue: Value?
    
    /// The current value of the environment property.
    var wrappedValue: Value? {
        guard let dynamicValue = storage else {
            fatalError("The wrapped value was accessed before it was activated.")
        }
        
        if let value = dynamicValue.value {
            return value
        }
        
        return nil
    }

    /// Sets the value for the given KeyPath.
    mutating func prepareValue(_ value: Value) {
        dynamicValue = value
    }
    
    /// Sets the value for the given KeyPath for an **activated** Environment.
    func setValue(_ value: Value) {
        guard let dynamicValue = storage else {
            fatalError("The wrapped value was accessed before it was activated.")
        }
        dynamicValue.value = value
    }
}

// MARK: Activatable

extension LocalEnvironment: Activatable {
    mutating func activate() {
        storage = Box(self.dynamicValue)
    }
}

extension Environment: Activatable {
    mutating func activate() {
        storage = Box(Storage(changed: false))
        _localEnvironment.activate()
    }
}

// MARK: ApplicationInjectable

/// Properties that need an `Application` instance.
protocol ApplicationInjectable {
    /// injects an `Application` instance
    mutating func inject(app: Application)
}

extension Environment: ApplicationInjectable {
    mutating func inject(app: Application) {
        self.app = app
    }
}

// MARK: KeyPathInjectable

protocol KeyPathInjectable {
    func inject<V>(_ value: V, for keyPath: AnyKeyPath)
}

extension Environment: KeyPathInjectable {
    func inject<V>(_ value: V, for keyPath: AnyKeyPath) {
        if keyPath == self.keyPath {
            if let typedValue = value as? Value {
                _localEnvironment.setValue(typedValue)
                (self as? any Observing)?.registerChildObservation()
            }
        }
    }
}

// MARK: EnvironmentAccessible

/// A protocol to define key paths that can be used with `@Environment` to retrieve pre-defined objects.
public protocol EnvironmentAccessible { }

extension Application: EnvironmentAccessible { }


// MARK: AnyObservedObject

extension Environment: AnyObservedObject, Observing where Value: ObservableObject {
    public var changed: Bool {
        guard let changed = storage?.value.changed else {
            fatalError("The changed flag was accessed before it was activated.")
        }
        return changed
    }
    
    public func setChanged(to value: Bool, reason event: TriggerEvent) {
        guard observe else {
            return
        }
        
        guard let store = storage else {
            fatalError("The changed flag was accessed before it was activated.")
        }
        store.value.changed = value
    }
    
    public func register(_ callback: @escaping (TriggerEvent) -> Void) -> Observation {
        guard observe else {
            return Observation(callback)
        }
        
        guard let storage = self.storage else {
            fatalError("An Environment was registered before it was activated.")
        }
        
        let ownObservation = Observation(callback)
        storage.value.ownObservation = ownObservation
        
        registerChildObservation()
        
        return ownObservation
    }
    
    fileprivate func registerChildObservation() {
        guard observe else {
            return
        }
        
        guard let storage = self.storage else {
            fatalError("An Environment registered to its child before it was activated.")
        }
        
        storage.value.count += 1
        let initialCount = storage.value.count
        
        let childObservation = Observation { [weak storage] triggerEvent in
            guard let storage = storage else {
                return
            }
            
            storage.value.ownObservation?.callback(TriggerEvent {
                triggerEvent.cancelled || initialCount != storage.value.count
            })
        }
        
        for property in Mirror(reflecting: wrappedValue).children {
            switch property.value {
            case let published as any AnyPublished:
                published.register(childObservation)
            default:
                continue
            }
        }
        
        storage.value.childObservation = childObservation
    }
}

private protocol Observing {
    func registerChildObservation()
}
