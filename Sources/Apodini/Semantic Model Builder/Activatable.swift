/// An `Activatable` element may allocate resources when `activate` is called. These
/// resources may share information with any copies made from this element after `activate`
/// was called.
public protocol Activatable {
    /// Activates the given element.
    mutating func activate()
}
