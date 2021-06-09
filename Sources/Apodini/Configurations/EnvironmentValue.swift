/// A `Configuration` which helps to store and retrieve objects using `@Environment` and the correspond key path.
///
/// A warning will be displayed if this action will overwrite a stored property.
public struct EnvironmentValue<Key: EnvironmentAccessible, Value>: Configuration {
    private let value: Value
    private let keyPath: KeyPath<Key, Value>
    
    /// initializer of `EnvironmentObject`.
    ///
    /// - Parameters:
    ///     - value: Object which is stored.
    ///     - keyPath: Associates a key path conforming to `EnvironmentAccessible` with the `value`.
    public init(_ value: Value, _ keyPath: KeyPath<Key, Value>) {
        self.value = value
        self.keyPath = keyPath
    }
    
    public func configure(_ app: Application) {
        if let oldValue = app.storage[keyPath] {
            app.logger.warning(
                """
                A value associated with the key path \(type(of: keyPath)) is already stored.
                The previous value \(String(describing: oldValue)) will be overwritten with \(String(describing: value))
                """
            )
        }
        app.storage[keyPath] = value
    }
}
