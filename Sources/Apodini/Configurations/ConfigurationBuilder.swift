/// A function builder used to aggregate multiple `ConfigurationConvertible`s to one `Configuration` or a collection of `Configuration`s of type `AnyConfigurationCollection`
@_functionBuilder
public enum ConfigurationBuilder {
    /// A method used to handle empty build blocks
    ///
    /// - Returns:  An `EmptyConfiguration`
    public static func buildBlock() -> EmptyConfiguration {
        EmptyConfiguration()
    }
    
    /// A method used to handle single `Configuration`s in build blocks
    ///
    /// - Parameter config: A `Configuration`
    ///
    /// - Returns: A `Configuration`
    public static func buildBlock<Config>(_ config: Config) -> Config where Config: Configuration {
        config
    }
    
    /// A method that transforms a variadic number of `Configuration`s which conform to `ConfigurationConvertible` to `AnyConfigurationCollection`
    ///
    /// - Parameter configs: A variadic number of `ConfigurationsConvertible`
    ///
    /// - Returns: An `AnyConfigurationCollection` which consists of `ConfigurationConvertible`s
    public static func buildBlock(_ configs: ConfigurationConvertible...) -> AnyConfigurationCollection {
        AnyConfigurationCollection(
            configs.map { $0.eraseToAnyConfiguration() }
        )
    }
    
    /// A method that enables the use of if-else statements for `Configuration`s
    ///
    /// - Parameter first: The `Configuration` within the if statement
    ///
    /// - Returns: The `Configuration` within the if statement
    public static func buildEither<C: Configuration>(first: C) -> C {
        first
    }
    
    /// A method that enables the use of if-else statements for `Configuration`s
    ///
    /// - Parameter second: The `Configuration` within the else statement
    ///
    /// - Returns: The `Configuration` within the else statement
    public static func buildEither<C: Configuration>(second: C) -> C {
        second
    }
    
    /// A method that enables the use of standalone if statements for `Configuration`s
    ///
    /// - Parameter configuration: The `Configuration` within the if statement
    ///
    /// - Returns: The `Configuration` within the if statement
    public static func buildIf<C: Configuration>(_ configuration: C?) -> C? {
        configuration
    }
}
