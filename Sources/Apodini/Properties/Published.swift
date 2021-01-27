/// Property wrapper that can be used to annotate properties inside of `ObservableObject`s.
/// The `ObservableObject` will notify its subscribers if a `Published` property changes.
@propertyWrapper
public class Published<Element>: Property {
    private var element: Element
    private var observations: [Weak<Observation>] = []
    
    public var wrappedValue: Element {
        get {
            element
        }
        set {
            element = newValue
            observations.removeAll { observation in
                observation.value == nil
            }
            observations.forEach { observation in
                observation.value?.callback()
            }
        }
    }
    /// Creates a new `Published` property.
    public init(wrappedValue: Element) {
        element = wrappedValue
    }
}

/// Type-erased `Published` protocol.
protocol AnyPublished {
    func register(_ observation: Observation)
}

extension Published: AnyPublished {
    /// Closure based approach is used for notifying any changes
    func register(_ observation: Observation) {
        self.observations.append(Weak<Observation>(value: observation))
    }
}

struct Weak<T: AnyObject> {
    weak var value: T?
}

public class Observation {
    let callback: () -> Void
    
    init(_ callback: @escaping () -> Void) {
        self.callback = callback
    }
}
