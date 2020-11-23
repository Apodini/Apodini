/// A protocol that offers an abstraction for `Configuration`s to allow conversion to `AnyConfiguration`
public protocol ConfigurationConvertible {
    /// A function that wraps this `Configuration` using type erasure
    ///
    /// - Returns: An `AnyConfiguration` that wraps the `Configuration`
    func eraseToAnyConfiguration() -> AnyConfiguration
}


extension EmptyConfiguration: ConfigurationConvertible {
    // swiftlint:disable:next unavailable_function
    public func eraseToAnyConfiguration() -> AnyConfiguration {
        fatalError("\(type(of: self)) has no body")
    }
}


extension DatabaseConfiguration: ConfigurationConvertible {
    public func eraseToAnyConfiguration() -> AnyConfiguration {
        AnyConfiguration(self)
    }
}


extension APNSConfiguration: ConfigurationConvertible {
    public func eraseToAnyConfiguration() -> AnyConfiguration {
        AnyConfiguration(self)
    }
}
