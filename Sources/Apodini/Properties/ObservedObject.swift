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
    
    private var objectIdentifer: ObjectIdentifier?
    private var element: Element?
    private var changedWrapper: Wrapper<Bool>
    
    /// Element passed as an object.
    public init(wrappedValue defaultValue: Element) {
        element = defaultValue
        changedWrapper = Wrapper(value: false)
    }
    
    /// Element is injected with a key path.
    public init<Key: KeyChain>(_ keyPath: KeyPath<Key, Element>) {
        objectIdentifer = ObjectIdentifier(keyPath)
        changedWrapper = Wrapper(value: false)
    }
}

/// Type-erased `ObservedObject` protocol.
public protocol AnyObservedObject {
    /// Method used to collect to `ObservedObject`s.
    func accept(_ observedObjectVisitor: ObservedObjectVisitor)
    /// Sets the `changed` property.
    func change(to value: Bool)
}

extension ObservedObject: AnyObservedObject {
    public func accept(_ observedObjectVisitor: ObservedObjectVisitor) {
        observedObjectVisitor.visit(self)
    }
    
    public nonmutating func change(to value: Bool) {
        changedWrapper.value = value
    }
}
