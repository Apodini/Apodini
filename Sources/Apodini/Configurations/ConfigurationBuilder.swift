//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// A function builder used to aggregate multiple `Configuration`s
@resultBuilder
public enum ConfigurationBuilder {
    /// A method that transforms multiple `Configuration`s
    ///
    /// - Parameter configurations: A variadic number of `ConfigurationsConvertible`
    ///
    /// - Returns: An `AnyConfigurationCollection` which consists of `ConfigurationConvertible`s
    public static func buildBlock(_ configurations: Configuration...) -> [Configuration] {
        configurations
    }
    
    
    /// A method that enables the use of standalone if statements for `Configuration`s.
    ///
    /// - Parameter configuration: The `Configuration` within the if statement.
    ///
    /// - Returns: Either the `Configuration` within the branch if the condition evaluates to `true` or an `EmptyConfiguration`.
    public static func buildIf(_ configuration: Configuration?) -> Configuration {
        configuration ?? EmptyConfiguration()
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
}
