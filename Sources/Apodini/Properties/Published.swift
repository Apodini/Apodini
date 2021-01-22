/// Property wrapper that can be used to annotate properties inside of `ObservableObject`s.
/// The `ObservableObject` will notify its subscribers if a `Published` property changes.
@propertyWrapper
public struct Published<Element>: Property {
    private var wrapper: Wrapper<Element>
    private var wrappedValueDidChange: Wrapper<(() -> Void)?>
    
    public var wrappedValue: Element {
        get {
            wrapper.value
        }
        nonmutating set {
            wrapper.value = newValue
            valueDidChange?()
        }
    }
    
    /// Creates a new `Published` property.
    public init(wrappedValue: Element) {
        wrapper = Wrapper(value: wrappedValue)
        wrappedValueDidChange = Wrapper(value: nil)
    }
}

/// Type-erased `Published` protocol.
protocol AnyPublished {
    var valueDidChange: (() -> Void)? { get nonmutating set }
}

extension Published: AnyPublished {
    /// Closure based approach is used for notifying any changes
    var valueDidChange: (() -> Void)? {
        get {
            wrappedValueDidChange.value
        }
        nonmutating set {
            wrappedValueDidChange.value = newValue
        }
    }
}
