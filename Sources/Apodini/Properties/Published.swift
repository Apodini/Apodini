import OpenCombine

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
            subject.send()
        }
    }

    private var wrapper: Wrapper<Element>
    private let subject: PassthroughSubject<Void, Never>
    
    /// Creates a new `Published` property.
    public init(wrappedValue: Element) {
        wrapper = Wrapper(value: wrappedValue)
        subject = PassthroughSubject()
    }
}

/// Type-erased `Publised` protocol.
protocol AnyPublished {
    var publisher: AnyPublisher<Void, Never> { get }
}

extension Published: AnyPublished {
    var publisher: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }
}
