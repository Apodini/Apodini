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
    public static func buildBlock<C0: Configuration, C1: Configuration>(_ c0: C0, _ c1: C1) -> AnyConfigurationCollection {
        return AnyConfigurationCollection(
            AnyConfiguration(c0),
            AnyConfiguration(c1)
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
