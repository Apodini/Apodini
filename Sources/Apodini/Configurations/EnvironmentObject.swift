import class Vapor.Application

/// A `Configuration` which helps to store and retrieve objects using `@Environment` and the correspond key path.
public struct EnvironmentObject<Key: ApodiniKeys, Value>: Configuration {
    private let value: Value
    private let keyPath: KeyPath<Key, Value>
    
    /// initializer of `EnvironmentObject`.
    ///
    /// - Parameters:
    ///     - value: Object which is stored.
    ///     - keyPath: Associates a key path conforming to `ApodiniKeys` with the `value`.
    public init(_ value: Value, _ keyPath: KeyPath<Key, Value>) {
        self.value = value
        self.keyPath = keyPath
    }
    
    public func configure(_ app: Vapor.Application) {
        if let previousValue = EnvironmentValues.shared.values[ObjectIdentifier(keyPath)] {
            print("""
                Warning: A value associated with the key path \(type(of: keyPath)) is already stored.
                The previous value \(String(describing: previousValue)) will be overwritten with \(String(describing: value)).
                """)
        }
        EnvironmentValues.shared.values[ObjectIdentifier(keyPath)] = value
    }
}
