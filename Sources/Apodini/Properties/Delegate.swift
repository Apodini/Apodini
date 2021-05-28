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
    struct DelegateStore {
        var connection: Connection?
        var didActivate = false
        // swiftlint:disable:next weak_delegate
        var delegate: D
        weak var observation: Observation?
        // swiftlint:disable:next discouraged_optional_collection
        var observations: [Observation]?
        // an ordered list of the observed objects that have fired last, i.e. .last holds the object that is next to cause an evaluation
        var observedObjectsQueue: [AnyObservedObject] = []
        var observedObjectsQueueLock = NSRecursiveLock()
        // storage for values injected via .environment
        var environment: [AnyKeyPath:Any] = [:]
        // storage for values injected via .environmentObject
        var environmentObject: [Any] = []
    }
    
    var delegateModel: D
    
    let optionality: Optionality
    
    var store: Box<DelegateStore>?
    
    /// Create a `Delegate` from the given struct `delegate`.
    /// - Parameter `delegate`: the wrapped instance
    /// - Parameter `optionality`: the `Optionality` for all `@Parameter`s of the `delegate`
    public init(_ delegate: D, _ optionality: Optionality = .optional) {
        self.delegateModel = delegate
        self.optionality = optionality
    }
    
    /// Prepare the wrapped delegate `D` for usage.
    public func callAsFunction() throws -> D {
        guard let store = store else {
            fatalError("'Delegate' was called before activation.")
        }
        
        // if not done yet we activate the delegate before injection
        if !store.value.didActivate {
            store.value.didActivate = true
            Apodini.activate(&store.value.delegate)
        }
        
        // we inject environment and environmentObject and invalidate both stores afterwards
        injectAll(values: store.value.environmentObject, into: store.value.delegate)
        store.value.environmentObject = []
        injectAll(values: store.value.environment, into: store.value.delegate)
        store.value.environment = [:]
        
        
        // if not done yet (and if the ConnectionContext has not canceled the observation yet),
        // we now wire up the real observations with the fake observation we passed to the
        // ConnectionContext earlier
        if store.value.observation != nil {
            if store.value.observations == nil {
                var observations = [Observation]()
                defer {
                    store.value.observations = observations
                }
                
                for object in collectObservedObjects(from: store.value.delegate) {
                    observations.append(object.register {
                        store.value.observedObjectsQueueLock.lock()
                        defer {
                            store.value.observedObjectsQueueLock.unlock()
                        }
                        
                        store.value.observedObjectsQueue = [object] + store.value.observedObjectsQueue
                        store.value.observation?.callback()
                    })
                }
            }
        } else {
            store.value.observations = []
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


extension Delegate {
    /// Set a delegate's `Binding` to a constant value. This allows for direct injection of information into
    /// a delegate.
    ///
    /// - Note: If the `Binding`'s initial value was a `Parameter`, this function changes the endpoint interface
    ///         at runtime to a certain degree. This has no impact on the framework or correctness of the endpoints
    ///         interface specification, however, a client might wonder why specifiying a certain input has no effect.
    @discardableResult
    public func set<V>(_ keypath: WritableKeyPath<D, Binding<V>>, to value: V) -> Delegate {
        guard let store = store else {
            fatalError("'Delegate' was manipulated before activation.")
        }
        
        store.value.delegate[keyPath: keypath] = Binding.constant(value)
        return self
    }
}

extension Delegate {
    @discardableResult
    public func environment<V>(_ keyPath: WritableKeyPath<Application, V>, _ value: V) -> Delegate {
        self.environment(at: keyPath, value)
    }
    
    @discardableResult
    public func environment<K, V>(_ keyPath: WritableKeyPath<K, V>, _ value: V) -> Delegate {
        self.environment(at: keyPath, value)
    }
    
    @discardableResult
    private func environment<K, V>(at keyPath: WritableKeyPath<K, V>, _ value: V) -> Delegate {
        guard let store = store else {
            fatalError("'Delegate' was manipulated before activation.")
        }
        
        store.value.environment[keyPath] = value
        return self
    }
}

extension Delegate {
    @discardableResult
    public func environmentObject<T>(_ object: T) -> Delegate {
        guard let store = store else {
            fatalError("'Delegate' was manipulated before activation.")
        }
        
        store.value.environmentObject.append(object)
        return self
    }
}




// MARK: Property Conformance

extension Delegate: Activatable {
    mutating func activate() {
        self.store = Box(DelegateStore(delegate: delegateModel))
    }
}

extension Delegate: KeyPathInjectable {
    func inject<V>(_ value: V, for keyPath: AnyKeyPath) {
        guard let store = store else {
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
        guard let store = store else {
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
    // The `changed` property is the tricky part here, because we cannot know which of
    // one of our internal observed objects really changed. We solve this problem by
    // keeping track of the internal observed objects that triggered and the order they
    // triggered in. We have to synchronize this with a lock to make sure we store the
    // observed objects in the same order as they arrive at the ConnectionContext.
    public var changed: Bool {
        get {
            guard let store = store else {
                fatalError("'Delegate' was injected with connection before activation.")
            }
            
            store.value.observedObjectsQueueLock.lock()
            defer {
                store.value.observedObjectsQueueLock.unlock()
            }
            
            return store.value.observedObjectsQueue.last?.changed ?? false
        }
        nonmutating set {
            guard let store = store else {
                fatalError("'Delegate' was injected with connection before activation.")
            }
            
            store.value.observedObjectsQueueLock.lock()
            defer {
                store.value.observedObjectsQueueLock.unlock()
            }
            
            if newValue {
                store.value.observedObjectsQueue.last?.changed = true
            } else {
                if let next = store.value.observedObjectsQueue.popLast() {
                    next.changed = false
                }
            }
        }
    }

    // When the framework wants to register the callback we just provide a new Observation.
    // We then have to wire up the callbacks later on, when we really start observing.
    public func register(_ callback: @escaping () -> Void) -> Observation {
        guard let store = store else {
            fatalError("'Delegate' was injected with connection before activation.")
        }
        
        let observation = Observation(callback)

        store.value.observation = observation
        return observation
    }
}
