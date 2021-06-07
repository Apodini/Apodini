//
//  EnvironmentObject.swift
//  
//
//  Created by Max Obermeier on 26.05.21.
//

import ApodiniUtils


@propertyWrapper
/// A property wrapper to inject pre-defined values  to a `Component`.  If `Value` is an
/// `ObservableObject`, `Environment` observes its value just as `ObservedObject`.
/// Use `Delegate.environmentObject(_:)` to inject a value.
public struct EnvironmentObject<Value>: DynamicProperty {
    private struct Storage {
        var changed: Bool
        weak var ownObservation: Observation?
        var childObservation: Observation?
        var count: UInt64 = 0
    }

    // only used if Value is ObservableObject
    private var storage: Box<Storage>?
    private let observe: Bool
    
    @LocalEnvironment private var localEnvironment: Value?
    
    /// Default initializer for `EnvironmentObject`
    public init() {
        self.observe = true
    }

    /// Initializer of `EnvironmentObject` for observable `Value`
    public init(observed: Bool) where Value: ObservableObject {
        self.observe = observed
    }

    /// The current value of the environment property.
    public var wrappedValue: Value {
        if let value = localEnvironment {
            return value
        }
        
        fatalError("No value of type \(Value.self) found in the local environment.")
    }
    
    /// A `Binding` that reflects this `Environment`.
    public var projectedValue: Binding<Value> {
        Binding.environment(self)
    }
}


// MARK: Activatable

extension EnvironmentObject: Activatable {
    mutating func activate() {
        storage = Box(Storage(changed: false))
        _localEnvironment.activate()
    }
}

// MARK: TypeInjectable

protocol TypeInjectable {
    func inject<V>(_ value: V)
}

extension EnvironmentObject: TypeInjectable {
    func inject<V>(_ value: V) {
        if let typedValue = value as? Value {
            _localEnvironment.setValue(typedValue)
            (self as? Observing)?.registerChildObservation()
        }
    }
}


// MARK: AnyObservedObject

extension EnvironmentObject: AnyObservedObject, Observing where Value: ObservableObject {
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
            case let published as AnyPublished:
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
