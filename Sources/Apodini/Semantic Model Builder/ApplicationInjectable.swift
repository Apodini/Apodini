/// Properties that need an `Application` instance.
public protocol ApplicationInjectable {
    /// injects an `Application` instance
    mutating func inject(app: Application)
}
