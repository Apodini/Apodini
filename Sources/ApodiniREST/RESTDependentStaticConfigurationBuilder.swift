//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// A function builder used to aggregate multiple `RESTDependentStaticConfiguration`s
@resultBuilder
public enum RESTDependentStaticConfigurationBuilder {
    /// A method that transforms multiple `RESTDependentStaticConfiguration`s
    ///
    /// - Parameter staticConfigurations: A variadic number of `RESTDependentStaticConfiguration`
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
