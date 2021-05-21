//
//  StaticConfigurationBuilder.swift
//  
//
//  Created by Philipp Zagar on 21.05.21.
//

/// A function builder used to aggregate multiple `StaticConfiguration`s
@_functionBuilder
public enum StaticConfigurationBuilder {
    /// A method that transforms multiple `StaticConfiguration`s
    ///
    /// - Parameter configs: A variadic number of `StaticConfiguration`
    ///
    /// - Returns: An `AnyConfigurationCollection` which consists of `ConfigurationConvertible`s
    public static func buildBlock(_ staticConfigurations: StaticConfiguration...) -> [StaticConfiguration] {
        staticConfigurations
    }
    
    
    /// A method that enables the use of standalone if statements for `StaticConfiguration`s.
    ///
    /// - Parameter configuration: The `StaticConfiguration` within the if statement.
    ///
    /// - Returns: Either the `StaticConfiguration` within the branch if the condition evaluates to `true` or an empty array.
    public static func buildIf(_ staticConfiguration: StaticConfiguration?) -> StaticConfiguration {
        staticConfiguration ?? EmptyStaticConfiguration()
    }
    
    
    /// A method that enables the use of if-else statements for `Configuration`s
    ///
    /// - Parameter first: The `Configuration` within the if statement
    ///
    /// - Returns: The `Configuration` within the if statement
    public static func buildEither(first: StaticConfiguration) -> StaticConfiguration {
        first
    }
    
    
    /// A method that enables the use of if-else statements for `Configuration`s
    ///
    /// - Parameter second: The `Configuration` within the else statement
    ///
    /// - Returns: The `Configuration` within the else statement
    public static func buildEither(second: StaticConfiguration) -> StaticConfiguration {
        second
    }
}
