//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// A function builder used to aggregate multiple `DependentStaticConfiguration`s
@resultBuilder
public enum DependentStaticConfigurationBuilder {
    /// A method that transforms multiple `DependentStaticConfiguration`s
    ///
    /// - Parameter staticConfigurations: A variadic number of `DependentStaticConfiguration`
    ///
    /// - Returns: An `AnyConfigurationCollection` which consists of `ConfigurationConvertible`s
    public static func buildBlock(_ staticConfigurations: DependentStaticConfiguration...) -> [DependentStaticConfiguration] {
        staticConfigurations
    }
    
    
    /// A method that enables the use of standalone if statements for `DependentStaticConfiguration`s.
    ///
    /// - Parameter staticConfiguration: The `DependentStaticConfiguration` within the if statement.
    ///
    /// - Returns: Either the `DependentStaticConfiguration` within the branch if the condition evaluates to `true` or an empty array.
    public static func buildIf(_ staticConfiguration: DependentStaticConfiguration?) -> DependentStaticConfiguration {
        staticConfiguration ?? EmptyDependentStaticConfiguration()
    }
    
    
    /// A method that enables the use of if-else statements for `DependentStaticConfiguration`s
    ///
    /// - Parameter first: The `DependentStaticConfiguration` within the if statement
    ///
    /// - Returns: The `DependentStaticConfiguration` within the if statement
    public static func buildEither(first: DependentStaticConfiguration) -> DependentStaticConfiguration {
        first
    }
    
    
    /// A method that enables the use of if-else statements for `DependentStaticConfiguration`s
    ///
    /// - Parameter second: The `DependentStaticConfiguration` within the else statement
    ///
    /// - Returns: The `DependentStaticConfiguration` within the else statement
    public static func buildEither(second: DependentStaticConfiguration) -> DependentStaticConfiguration {
        second
    }
}
