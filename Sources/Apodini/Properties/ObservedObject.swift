import Foundation


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
    
    public var changed: Bool {
        get {
            changedWrapper.value
        }
    }
    
    var objectIdentifer: ObjectIdentifier?
    private var element: Element?
    private var changedWrapper: Wrapper<Bool>
    
    public init(wrappedValue defaultValue: Element) {
        element = defaultValue
        changedWrapper = Wrapper(value: false)
    }
    
    public init<Key: KeyChain>(_ keyPath: KeyPath<Key, Element>) {
        objectIdentifer = ObjectIdentifier(keyPath)
        changedWrapper = Wrapper(value: false)
    }
}

public protocol AnyObservedObject {
    func accept(_ observedObjectVisitor: ObservedObjectVisitor)
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
