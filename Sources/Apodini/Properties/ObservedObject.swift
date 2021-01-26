import Foundation

/// Property wrapper used inside of a `Handler` or `Job` that subscribes to an `ObservableObject`.
/// Changes of `@Published` properties of the `ObservableObject` will cause re-evaluations of the `Handler` or `Job`.
/// `ObservableObject`s can either be passed to the property wrapper as instances or in form of key paths from the environment.
///
/// This is helpful for service-side streams or bidirectional communication.
@propertyWrapper
public struct ObservedObject<Element: ObservableObject>: Property {
    private var objectIdentifer: ObjectIdentifier?
    private var element: Element?
    
    public var wrappedValue: Element {
        get {
            if let element = element {
                return element
            }
            if let objectIdentifer = objectIdentifer,
               let element = EnvironmentValues.shared.values[objectIdentifer] as? Element {
                return element
            }
            fatalError("The object \(String(describing: self)) cannot be found in the environment.")
        }
        set {
            element = newValue
        }
    }
    
    private var changedWrapper: Wrapper<Bool>?
    
    /// Property to check if the evaluation of the `Handler` or `Job` was triggered by this `ObservableObject`.
    /// Read only property
    public internal (set) var changed: Bool {
        get {
            guard let value = changedWrapper?.value else {
                fatalError("""
                    A ObservedObjects's 'changed' property was accessed before the
                    ObservedObject was activated.
                    """)
            }
            return value
        }
        nonmutating set {
            guard let wrapper = changedWrapper else {
                fatalError("""
                    A ObservedObjects's 'changed' property was accessed before the
                    ObservedObject was activated.
                    """)
            }
            wrapper.value = newValue
        }
    }
    
    /// Element passed as an object.
    public init(wrappedValue defaultValue: Element) {
        element = defaultValue
    }
    
    /// Element is injected with a key path.
    public init<Key: KeyChain>(_ keyPath: KeyPath<Key, Element>) {
        objectIdentifer = ObjectIdentifier(keyPath)
    }
}

/// Type-erased `ObservedObject` protocol.
protocol AnyObservedObject {
    /// Method to be informed about values that have changed
    func register(_ callback: @escaping () -> Void) -> Observation
    
    var changed: Bool { get nonmutating set }
}

extension ObservedObject: AnyObservedObject {
    func register(_ callback: @escaping () -> Void) -> Observation {
        let observation = Observation(callback)
    
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

extension ObservedObject: Activatable {
    mutating func activate() {
        self.changedWrapper = Wrapper(value: false)
    }
}
