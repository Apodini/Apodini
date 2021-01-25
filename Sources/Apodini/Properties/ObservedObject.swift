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
    private var changedWrapper: Wrapper<Bool>
    private var wrappedValueDidChange: Wrapper<(() -> Void)?>
    
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
    
    /// Property to check if the evaluation of the `Handler` or `Job` was triggered by this `ObservableObject`.
    /// Read only property
    public var changed: Bool {
        changedWrapper.value
    }
    
    /// Element passed as an object.
    public init(wrappedValue defaultValue: Element) {
        element = defaultValue
        changedWrapper = Wrapper(value: false)
        wrappedValueDidChange = Wrapper(value: nil)
    }
    
    /// Element is injected with a key path.
    public init<Key: KeyChain>(_ keyPath: KeyPath<Key, Element>) {
        objectIdentifer = ObjectIdentifier(keyPath)
        changedWrapper = Wrapper(value: false)
        wrappedValueDidChange = Wrapper(value: nil)
    }
}

/// Type-erased `ObservedObject` protocol.
public protocol AnyObservedObject {
    /// Method to be informed about values that have changed
    var valueDidChange: (() -> Void)? { get nonmutating set }
    /// Sets the `changed` property.
    /// Separate setter for `changed` to be read only by the user.
    nonmutating func setChanged(to value: Bool)
}

extension ObservedObject: AnyObservedObject {
    public var valueDidChange: (() -> Void)? {
        get {
            wrappedValueDidChange.value
        }
        nonmutating set {
            wrappedValueDidChange.value = newValue
            
            for property in Mirror(reflecting: wrappedValue).children {
                switch property.value {
                case let published as AnyPublished:
                    published.valueDidChange = valueDidChange
                default:
                    continue
                }
            }
        }
    }
    
    public nonmutating func setChanged(to value: Bool) {
        changedWrapper.value = value
    }
}

extension Handler {
    /// Collects  every `ObservedObject` in the Handler.
    func collectObservedObjects() -> [AnyObservedObject] {
        var observedObjects: [AnyObservedObject] = []
        
        for property in Mirror(reflecting: self).children {
            switch property.value {
            case let observedObject as AnyObservedObject:
                observedObjects.append(observedObject)
            default:
                continue
            }
        }
        
        return observedObjects
    }
}
