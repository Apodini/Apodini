import OpenCombine

@propertyWrapper
public struct Published<Element>: Property {
    private var wrapper: Wrapper<Element>
    
    public var wrappedValue: Element {
        get {
            wrapper.value
        }
        nonmutating set {
            wrapper.value = newValue
            subject.send()
        }
    }

    private let subject: PassthroughSubject<Void, Never>
    
    public init(wrappedValue: Element) {
        wrapper = Wrapper(value: wrappedValue)
        subject = PassthroughSubject()
    }
}

protocol AnyPublished {
    var publisher: AnyPublisher<Void, Never> { get }
}

extension Published: AnyPublished {
    var publisher: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }
}
