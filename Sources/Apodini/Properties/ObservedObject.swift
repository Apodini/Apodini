import Foundation

/// Property wrapper that subscribes to an `ObservableObject` and evaluates a `Handler` or `Job` on changes.
///
/// Refer to the documentation of
/// [ObservedObject](https://github.com/Apodini/Apodini/blob/develop/Documentation/Communicational%20Patterns/2.%20Tooling/2.4.%20ObservedObject.md)
/// for more information.
@propertyWrapper
public struct ObservedObject<Element: ObservableObject>: Property {
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
    public var changed: Bool {
        changedWrapper.value
    }
    
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

    private var objectIdentifer: ObjectIdentifier?
    private var element: Element?
    private var changedWrapper: Wrapper<Bool>
    private var wrappedValueDidChange: Wrapper<(() -> Void)?>
    
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
    nonmutating func setChanged(to value: Bool)
}

extension ObservedObject: AnyObservedObject {
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
