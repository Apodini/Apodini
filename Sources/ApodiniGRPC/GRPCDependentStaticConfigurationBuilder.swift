//
//  GRPCDependentStaticConfigurationBuilder.swift
//  
//
//  Created by Philipp Zagar on 27.05.21.
//

/// A function builder used to aggregate multiple `GRPCDependentStaticConfiguration`s
#if swift(>=5.4)
@resultBuilder
public enum GRPCDependentStaticConfigurationBuilder {}
#else
@_functionBuilder
public enum GRPCDependentStaticConfigurationBuilder {}
#endif

public extension GRPCDependentStaticConfigurationBuilder {
    /// A method that transforms multiple `GRPCDependentStaticConfiguration`s
    ///
    /// - Parameter staticConfigurations: A variadic number of `GRPCDependentStaticConfiguration`
    ///
    /// - Returns: An `AnyConfigurationCollection` which consists of `ConfigurationConvertible`s
    static func buildBlock(_ staticConfigurations: GRPCDependentStaticConfiguration...) -> [GRPCDependentStaticConfiguration] {
        staticConfigurations
    }
    
    
    /// A method that enables the use of standalone if statements for `GRPCDependentStaticConfiguration`s.
    ///
    /// - Parameter staticConfiguration: The `GRPCDependentStaticConfiguration` within the if statement.
    ///
    /// - Returns: Either the `GRPCDependentStaticConfiguration` within the branch if the condition evaluates to `true` or an empty array.
    static func buildIf(_ staticConfiguration: GRPCDependentStaticConfiguration?) -> GRPCDependentStaticConfiguration {
        staticConfiguration ?? EmptyGRPCDependentStaticConfiguration()
    }
    
    
    /// A method that enables the use of if-else statements for `GRPCDependentStaticConfiguration`s
    ///
    /// - Parameter first: The `GRPCDependentStaticConfiguration` within the if statement
    ///
    /// - Returns: The `GRPCDependentStaticConfiguration` within the if statement
    static func buildEither(first: GRPCDependentStaticConfiguration) -> GRPCDependentStaticConfiguration {
        first
    }
    
    
    /// A method that enables the use of if-else statements for `GRPCDependentStaticConfiguration`s
    ///
    /// - Parameter second: The `GRPCDependentStaticConfiguration` within the else statement
    ///
    /// - Returns: The `GRPCDependentStaticConfiguration` within the else statement
    static func buildEither(second: GRPCDependentStaticConfiguration) -> GRPCDependentStaticConfiguration {
        second
    }
}
