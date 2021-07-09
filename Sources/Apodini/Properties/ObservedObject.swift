import ApodiniUtils


/// Property wrapper used inside of a `Handler` or `Job` that subscribes to an `ObservableObject`.
/// Changes of `@Published` properties of the `ObservableObject` will cause re-evaluations of the `Handler` or `Job`.
///
/// This is helpful for service-side streams or bidirectional communication.
@propertyWrapper
public struct ObservedObject<Element: ObservableObject>: _InstanceCodable, Property {
    private struct Storage {
        var changed: Bool
        var element: Element
        weak var ownObservation: Observation?
        var childObservation: Observation?
        var count: UInt64 = 0
    }
    
    private let _initializer: () -> Element
    
    private var storage: Box<Storage>?
    
    public var wrappedValue: Element {
        get {
            if let element = storage?.value.element {
                return element
            }
            fatalError("The object \(String(describing: self)) was accessed before it was activated.")
        }
        nonmutating set {
            guard let store = storage else {
                fatalError("ObservedObject.wrappedValue was mutated before it was activated.")
            }
            
            store.value.element = newValue
            registerChildObservation()
        }
    }
    
    /// Property to check if the evaluation of the `Handler` or `Job` was triggered by this `ObservableObject`.
    public var changed: Bool {
        guard let value = storage?.value.changed else {
            fatalError("""
                A ObservedObjects's 'changed' property was accessed before the
                ObservedObject was activated.
                """)
        }
        return value
    }
    
    public var projectedValue: Self {
        get {
            self
        }
        set {
            self = newValue
        }
    }
    
    /// Element passed as an object.
    public init(wrappedValue initializer: @escaping @autoclosure () -> Element) {
        self._initializer = initializer
    }
}

/// Type-erased `ObservedObject` protocol.
public protocol AnyObservedObject {
    /// Method to be informed about values that have changed
    func register(_ callback: @escaping (TriggerEvent) -> Void) -> Observation
    
    /// Any `ObservedObject` should have a `changed` flag that indicates if this object has been
    /// changed _recently_. The definition of _recently_ depends on the context and usage.
    ///
    /// E.g. for `Handler`s, the `handle()` function is executed every time an `@ObservedObject`
    /// changes. The `changed` property of this object is set to `true` for the exact time where
    /// the `handle()` is evaluated because this object changed.
    /// This method can be used to control the value of the `changed` property.
    func setChanged(to value: Bool, reason event: TriggerEvent)
}

extension ObservedObject: AnyObservedObject {
    public func register(_ callback: @escaping (TriggerEvent) -> Void) -> Observation {
        guard let storage = self.storage else {
            fatalError("An ObservedObject was registered before it was activated.")
        }
        
        let ownObservation = Observation(callback)
        storage.value.ownObservation = ownObservation
        
        registerChildObservation()
        
        return ownObservation
    }
    
    public func setChanged(to value: Bool, reason event: TriggerEvent) {
        guard let wrapper = storage else {
            fatalError("""
                A ObservedObjects's 'changed' property was accessed before the
                ObservedObject was activated.
                """)
        }
        wrapper.value.changed = value
    }
    
    private func registerChildObservation() {
        guard let storage = self.storage else {
            fatalError("An ObservedObject registered to its child before it was activated.")
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

extension ObservedObject: Activatable {
    mutating func activate() {
        self.storage = Box(Storage(changed: false, element: self._initializer()))
    }
}

/// An `Observation` is a token that is obtained from registering a callback to an `ObservedObject`.
/// The registering instance must hold this token until it no longer wishes to be updated about the
/// `ObservedObject`'s state. When the token is released, the subscription is canceled.
public class Observation {
    let callback: (TriggerEvent) -> Void
    
    /// Create a new `Observation`
    /// - Note: Make sure the `callback` holds no strong references! Otherwise, you will most likely
    ///         create a memory-leak!
    internal init(_ callback: @escaping (TriggerEvent) -> Void) {
        self.callback = callback
    }
}

/// A `TriggerEvent` is emitted by an `ObservableObject`'s `Published` properties when they change.
/// - Note: Always check the `cancelled` property before acting in behalf of the event.
public struct TriggerEvent {
    let checkCancelled: () -> Bool
    
    let identifier: TriggerIdentifier
    
    internal init(_ cancelled: @escaping () -> Bool = { false }, id: TriggerIdentifier = .this) {
        self.checkCancelled = cancelled
        self.identifier = id
    }
    
    /// Indicates if the event is outdated. If `true`, discard the event and abort the triggered action.
    public var cancelled: Bool {
        checkCancelled()
    }
}

indirect enum TriggerIdentifier {
    case this
    case index(Int, TriggerIdentifier)
}
