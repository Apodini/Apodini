/// Property wrapper that can be used to annotate properties inside of `ObservableObject`s.
/// The `ObservableObject` will notify its subscribers if a `Published` property changes.
///
/// Refer to the documentation of
/// [ObservedObject](https://github.com/Apodini/Apodini/blob/develop/Documentation/Communicational%20Patterns/2.%20Tooling/2.4.%20ObservedObject.md)
/// for more information.
@propertyWrapper
public struct Published<Element>: Property {
    public var wrappedValue: Element {
        get {
            wrapper.value
        }
        nonmutating set {
            wrapper.value = newValue
            valueDidChange?()
        }
    }

    private var wrapper: Wrapper<Element>
    private var wrappedValueDidChange: Wrapper<(() -> Void)?>
    
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
    var valueDidChange: (() -> Void)? {
        get {
            wrappedValueDidChange.value
        }
        nonmutating set {
            wrappedValueDidChange.value = newValue
        }
    }
}
