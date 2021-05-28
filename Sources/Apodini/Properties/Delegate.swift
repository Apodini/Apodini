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
        
        guard let connection = store.value.connection else {
            fatalError("'Delegate' was called before injection with connection.")
        }
        
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

extension Delegate: Activatable {
    mutating func activate() {
        self.store = Box(DelegateStore(delegate: delegateModel))
    }
}

extension Delegate: ConnectionInjectable {
    func inject(connection: Connection) {
        guard let store = store else {
            fatalError("'Delegate' was injected with connection before activation.")
        }
        
        store.value.connection = connection
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
