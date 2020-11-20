//
//  ConfigurationBuilder.swift
//  
//
//  Created by Alexander Collins on 18.11.20.
//


@_functionBuilder
public struct ConfigurationBuilder {
    public static func buildBlock() {
    
    }
    
    static func buildBlock<C: Configuration>(_ configurations: C...) -> [C] {
        configurations
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
