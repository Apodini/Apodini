//
//  EnvironmentObject.swift
//  
//
//  Created by Max Obermeier on 26.05.21.
//

import ApodiniUtils


@propertyWrapper
/// A property wrapper to inject pre-defined values  to a `Component`.
public struct EnvironmentObject<Value>: DynamicProperty {

    // only used if Value is ObservableObject
    private var _changed: Box<Bool>?
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
        _changed = Box(false)
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
        }
    }
}


// MARK: AnyObservedObject

extension EnvironmentObject: AnyObservedObject where Value: ObservableObject {
    public var changed: Bool {
        guard let changed = _changed else {
            fatalError("The changed flag was accessed before it was activated.")
        }
        return changed.value
    }
    
    public func setChanged(to value: Bool, reason event: TriggerEvent) {
        guard let changed = _changed else {
            fatalError("The changed flag was accessed before it was activated.")
        }
        changed.value = value
    }
    
    public func register(_ callback: @escaping (TriggerEvent) -> Void) -> Observation {
        let observation = Observation(callback)
        
        guard observe else { return observation }
    
        for property in Mirror(reflecting: wrappedValue).children {
            switch property.value {
            case let published as AnyPublished:
                published.register(observation)
            default:
                continue
            }
        }
        
        return observation
    }
}
