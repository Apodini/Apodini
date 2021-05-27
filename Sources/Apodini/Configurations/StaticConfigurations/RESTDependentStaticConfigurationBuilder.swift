//
//  RESTDependentStaticConfigurationBuilder.swift
//  
//
//  Created by Philipp Zagar on 27.05.21.
//

@_functionBuilder
/// A function builder used to aggregate multiple `RESTDependentStaticConfiguration`s
public enum RESTDependentStaticConfigurationBuilder {
    /// A method that transforms multiple `RESTDependentStaticConfiguration`s
    ///
    /// - Parameter configs: A variadic number of `RESTDependentStaticConfiguration`
    ///
    /// - Returns: An `AnyConfigurationCollection` which consists of `ConfigurationConvertible`s
    public static func buildBlock(_ staticConfigurations: RESTDependentStaticConfiguration...) -> [RESTDependentStaticConfiguration] {
        staticConfigurations
    }
    
    
    /// A method that enables the use of standalone if statements for `RESTDependentStaticConfiguration`s.
    ///
    /// - Parameter staticConfiguration: The `RESTDependentStaticConfiguration` within the if statement.
    ///
    /// - Returns: Either the `RESTDependentStaticConfiguration` within the branch if the condition evaluates to `true` or an empty array.
    public static func buildIf(_ staticConfiguration: RESTDependentStaticConfiguration?) -> RESTDependentStaticConfiguration {
        staticConfiguration ?? EmptyRESTDependentStaticConfiguration()
    }
    
    
    /// A method that enables the use of if-else statements for `RESTDependentStaticConfiguration`s
    ///
    /// - Parameter first: The `RESTDependentStaticConfiguration` within the if statement
    ///
    /// - Returns: The `RESTDependentStaticConfiguration` within the if statement
    public static func buildEither(first: RESTDependentStaticConfiguration) -> RESTDependentStaticConfiguration {
        first
    }
    
    
    /// A method that enables the use of if-else statements for `RESTDependentStaticConfiguration`s
    ///
    /// - Parameter second: The `RESTDependentStaticConfiguration` within the else statement
    ///
    /// - Returns: The `RESTDependentStaticConfiguration` within the else statement
    public static func buildEither(second: RESTDependentStaticConfiguration) -> RESTDependentStaticConfiguration {
        second
    }
}
