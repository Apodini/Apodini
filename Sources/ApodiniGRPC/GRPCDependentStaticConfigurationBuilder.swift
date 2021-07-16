//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
/// A function builder used to aggregate multiple `GRPCDependentStaticConfiguration`s
@resultBuilder
public enum GRPCDependentStaticConfigurationBuilder {
    /// A method that transforms multiple `GRPCDependentStaticConfiguration`s
    ///
    /// - Parameter staticConfigurations: A variadic number of `GRPCDependentStaticConfiguration`
    ///
    /// - Returns: An `AnyConfigurationCollection` which consists of `ConfigurationConvertible`s
    public static func buildBlock(_ staticConfigurations: GRPCDependentStaticConfiguration...) -> [GRPCDependentStaticConfiguration] {
        staticConfigurations
    }
    
    
    /// A method that enables the use of standalone if statements for `GRPCDependentStaticConfiguration`s.
    ///
    /// - Parameter staticConfiguration: The `GRPCDependentStaticConfiguration` within the if statement.
    ///
    /// - Returns: Either the `GRPCDependentStaticConfiguration` within the branch if the condition evaluates to `true` or an empty array.
    public static func buildIf(_ staticConfiguration: GRPCDependentStaticConfiguration?) -> GRPCDependentStaticConfiguration {
        staticConfiguration ?? EmptyGRPCDependentStaticConfiguration()
    }
    
    
    /// A method that enables the use of if-else statements for `GRPCDependentStaticConfiguration`s
    ///
    /// - Parameter first: The `GRPCDependentStaticConfiguration` within the if statement
    ///
    /// - Returns: The `GRPCDependentStaticConfiguration` within the if statement
    public static func buildEither(first: GRPCDependentStaticConfiguration) -> GRPCDependentStaticConfiguration {
        first
    }
    
    
    /// A method that enables the use of if-else statements for `GRPCDependentStaticConfiguration`s
    ///
    /// - Parameter second: The `GRPCDependentStaticConfiguration` within the else statement
    ///
    /// - Returns: The `GRPCDependentStaticConfiguration` within the else statement
    public static func buildEither(second: GRPCDependentStaticConfiguration) -> GRPCDependentStaticConfiguration {
        second
    }
}
