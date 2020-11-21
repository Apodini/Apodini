//
//  ConfigurationBuilder.swift
//  
//
//  Created by Alexander Collins on 18.11.20.
//


@_functionBuilder
public struct ConfigurationBuilder {
    
    public static func buildBlock() -> EmptyConfiguration {
        EmptyConfiguration()
    }
    
    public static func buildBlock<Config>(_ config: Config) -> Config where Config: Configuration {
        config
    }
    public static func buildBlock(_ configs: ConfigurationConvertible...) -> AnyConfigurationCollection {
        return AnyConfigurationCollection(
            configs.map { $0.eraseToAnyConfiguration() }
        )
    }
    
    public static func buildEither<C: Configuration>(first: C) -> C {
        first
    }
    
    public static func buildEither<C: Configuration>(second: C) -> C {
        second
    }
    
    public static func buildIf<C: Configuration>(_ configuration: C?) -> C? {
        configuration
    }
}
