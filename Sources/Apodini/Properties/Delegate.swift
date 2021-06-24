//
//  Delegate.swift
//  
//
//  Created by Max Obermeier on 17.05.21.
//

import ApodiniUtils
import Foundation

/// A `Delegate` is a lazy version of `DynamicProperty`. That is, your delegate `D` can wrap
/// multiple `Property`s and their functionality is maintained. The `Delegate` type makes its wrapped
/// instance of `D` discoverable to the Apodini runtime framework. Moreover, it delays initialization and verification
/// of `@Parameter`s to the point where you call `Delegate` as a function. This enables you to decode
/// input lazily and to do manual error handling in case decoding fails.
/// - Warning: `D` must be a `struct`
public struct Delegate<D> {
    struct Storage {
        var connection: Connection?
        var didActivate = false
        // swiftlint:disable:next weak_delegate
        var delegate: D
        weak var observation: Observation?
        // swiftlint:disable:next discouraged_optional_collection
        var observables: [(AnyObservedObject, Observation)]?
        var changed = false
        // storage for observable objects set via .setObservable
        var observableObjectsSetters: [() -> Void] = []
        // storage for values injected via .environment
        var environment: [AnyKeyPath: Any] = [:]
        // storage for values injected via .environmentObject
        var environmentObject: [Any] = []
    }
    
    var delegateModel: D
    
    let optionality: Optionality
    
    var storage: Box<Storage>?
    
    /// Create a `Delegate` from the given struct `delegate`.
    /// - Parameter `delegate`: the wrapped instance
    /// - Parameter `optionality`: the `Optionality` for all `@Parameter`s of the `delegate`
    public init(_ delegate: D, _ optionality: Optionality = .optional) {
        self.delegateModel = delegate
        self.optionality = optionality
    }
    
    /// Prepare the wrapped delegate `D` for usage.
    public func callAsFunction() throws -> D {
        guard let store = storage else {
            fatalError("'Delegate' was called before activation.")
        }
        
        // if not done yet we activate the delegate before injection
        if !store.value.didActivate {
            store.value.didActivate = true
            Apodini.activate(&store.value.delegate)
        }
        
        // we inject observedobjects, environment and environmentObject and invalidate all stores afterwards
        store.value.observableObjectsSetters.forEach { closure in closure() }
        store.value.observableObjectsSetters = []
        injectAll(values: store.value.environmentObject, into: store.value.delegate)
        store.value.environmentObject = []
        injectAll(values: store.value.environment, into: store.value.delegate)
        store.value.environment = [:]
        
        
        // if not done yet (and if the ConnectionContext has not canceled the observation yet),
        // we now wire up the real observations with the fake observation we passed to the
        // ConnectionContext earlier
        if store.value.observation != nil {
            if store.value.observables == nil {
                var observables = [(AnyObservedObject, Observation)]()
                defer {
                    store.value.observables = observables
                }
                
                for object in collectObservedObjects(from: store.value.delegate) {
                    let index = observables.count
                    observables.append((object, object.register { triggerEvent in
                        store.value.observation?.callback(TriggerEvent(triggerEvent.checkCancelled, id: .index(index, triggerEvent.identifier)))
                    }))
                }
            }
        } else {
            // the delegate isn't observed anymore, thus we also drop the references
            // to all child-observations
            store.value.observables = []
        }
        
        guard let connection = store.value.connection else {
            fatalError("'Delegate' was called before injection with connection.")
        }
        
        // finally we inject everything and return the prepared delegate
        try connection.enterConnectionContext(with: store.value.delegate, executing: { _ in Void() })
        
        return store.value.delegate
    }
}

/// A generic `PropertyOption` that indicates if the `@Parameter` decoded and validated at all times. Setting this option won't
/// affect runtime behavior. The option allows for customizing documentation where Apodini cannot automatically determine if an
/// `@Parameter` will actually be decoded.
/// - Note: This type is only to be used on `Delegate`.
public enum Optionality: PropertyOption {
    /// Default for `@Parameter`s behind a `Delegate`. Documentation should show this parameter as not required.
    case optional
    /// Default for normal `@Parameter`s, i.e. such that are not behind a `Delegate`. Pass this to a `Delegate`, if there is no path
    /// throgh your `handle()` that doesn't `throw` where the `Delegate` is not called.
    case required
}

extension PropertyOptionKey where PropertyNameSpace == ParameterOptionNameSpace, Option == Optionality {
    /// The key for `Optionality` of a `Parameter`
    public static let optionality = PropertyOptionKey<ParameterOptionNameSpace, Optionality>()
}

extension Optionality {
    /// Reduction of ``Optionality`` favors ``Optionality/optional``, i.e. ``Optionality``
    /// will always be ``Optionality/optional``, except when all reduced elements are ``Optionality/required``.
    public static func & (lhs: Self, rhs: Self) -> Self {
        lhs == .optional ?.optional : rhs
    }
}


extension Delegate {
    /// Set a delegate's `Binding` to a constant value. This allows for direct injection of information into
    /// a delegate.
    ///
    /// - Note: If the `Binding`'s initial value was a `Parameter`, this function changes the endpoint interface
    ///         at runtime to a certain degree. This has no impact on the framework or correctness of the endpoints
    ///         interface specification, however, a client might wonder why specifiying a certain input has no effect.
    @discardableResult
    public func set<V>(_ keypath: WritableKeyPath<D, Binding<V>>, to value: V) -> Delegate {
        guard let store = storage else {
            fatalError("'Delegate' was manipulated before activation.")
        }
        
        store.value.delegate[keyPath: keypath] = Binding.constant(value)
        return self
    }
}


extension Delegate {
    /// Change a `delegate`'s `ObservedObject` to observe another `value`.
    @discardableResult
    public func setObservable<V: ObservableObject>(_ keypath: WritableKeyPath<D, ObservedObject<V>>, to value: V) -> Delegate {
        guard let store = storage else {
            fatalError("'Delegate' was manipulated before activation.")
        }
        
        store.value.observableObjectsSetters.append {
            store.value.delegate[keyPath: keypath].wrappedValue = value
        }
        
        return self
    }
}

extension Delegate {
    /// Inject a local `value` into the `delegate`'s `Environment` properties that are based on the given `keyPath`.
    @discardableResult
    public func environment<V>(_ keyPath: WritableKeyPath<Application, V>, _ value: V) -> Delegate {
        self.environment(at: keyPath, value)
    }
    
    /// Inject a local `value` into the `delegate`'s `Environment` properties that are based on the given `keyPath`.
    @discardableResult
    public func environment<K, V>(_ keyPath: WritableKeyPath<K, V>, _ value: V) -> Delegate {
        self.environment(at: keyPath, value)
    }
    
    @discardableResult
    private func environment<K, V>(at keyPath: WritableKeyPath<K, V>, _ value: V) -> Delegate {
        guard let store = storage else {
            fatalError("'Delegate' was manipulated before activation.")
        }
        
        store.value.environment[keyPath] = value
        return self
    }
}

extension Delegate {
    /// Inject a local `value` into the `delegate`'s `EnvironmentObject` properties that are of type `T`.
    @discardableResult
    public func environmentObject<T>(_ object: T) -> Delegate {
        guard let store = storage else {
            fatalError("'Delegate' was manipulated before activation.")
        }
        
        store.value.environmentObject.append(object)
        return self
    }
}


// MARK: Property Conformance

extension Delegate: Activatable {
    mutating func activate() {
        self.storage = Box(Storage(delegate: delegateModel))
    }
}

extension Delegate: KeyPathInjectable {
    func inject<V>(_ value: V, for keyPath: AnyKeyPath) {
        guard let store = storage else {
            fatalError("'Delegate' was injected with connection before activation.")
        }
        if keyPath == \Application.connection {
            if let connection = value as? Connection {
                store.value.connection = connection
            }
        } else {
            store.value.environment[keyPath] = value
        }
    }
}

extension Delegate: TypeInjectable {
    func inject<V>(_ value: V) {
        guard let store = storage else {
            fatalError("'Delegate' was injected with connection before activation.")
        }
        store.value.environmentObject.append(value)
    }
}

extension Delegate: RequestInjectable {
    // We conform `Delegate` to `RequestInjectable`. This way requests are not injected into the `delegate` right away.
    func inject(using request: Request) throws { }
}

// Delegate bundles all contained ObservedObjects into one.
extension Delegate: AnyObservedObject {
    /// Indicates if the current evaluation was caused by one of the `delegate`'s child-properties (e.g. an `ObservedObject`.
    public var changed: Bool {
        guard let store = storage else {
            fatalError("'Delegate''s AnyObservedObject property was used before activation.")
        }
        
        return store.value.changed
    }
    
    public func setChanged(to value: Bool, reason event: TriggerEvent) {
        guard let store = storage else {
            fatalError("'Delegate''s AnyObservedObject property was used before activation.")
        }
        
        guard let observables = store.value.observables else {
            fatalError("'Delegate''s 'changed' property was set while not prepared vor observing")
        }
        
        switch event.identifier {
        case let .index(index, identifier):
            observables[index].0.setChanged(to: value, reason: TriggerEvent(event.checkCancelled, id: identifier))
        default:
            fatalError("'Delegate' was passed a 'TriggerEvent' which's 'identifier' was no '.index'")
        }
        
        store.value.changed = value
    }

    // When the framework wants to register the callback we just provide a new Observation.
    // We then have to wire up the callbacks later on, when we really start observing.
    public func register(_ callback: @escaping (TriggerEvent) -> Void) -> Observation {
        guard let store = storage else {
            fatalError("'Delegate''s AnyObservedObject property was used before activation.")
        }
        
        let observation = Observation(callback)

        store.value.observation = observation
        return observation
    }
}
