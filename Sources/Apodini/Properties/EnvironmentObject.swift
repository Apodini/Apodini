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
        
        fatalError("Key path not found")
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

// MARK: AnyObservedObject

extension EnvironmentObject: AnyObservedObject where Value: ObservableObject {
    public var changed: Bool {
        get {
            guard let changed = _changed else {
                fatalError("The changed flag was accessed before it was activated.")
            }
            return changed.value
        }
        nonmutating set {
            guard let changed = _changed else {
                fatalError("The changed flag was accessed before it was activated.")
            }
            changed.value = newValue
        }
    }
    
    public func register(_ callback: @escaping () -> Void) -> Observation {
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
