import ApodiniUtils

/// Property wrapper that can be used to annotate properties inside of `ObservableObject`s.
/// The `ObservableObject` will notify its subscribers if a `Published` property changes.
@propertyWrapper
public class Published<Element> {
    private var element: Element
    private var observations: [Weak<Observation>] = []
    
    /// The contained element. When changed all subscribed entities are notified
    /// **after** the new value has been set.
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
                observation.value?.callback(TriggerEvent())
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
        self.observations.append(Weak<Observation>(observation))
    }
}
