//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// A function builder used to aggregate multiple `HTTPDependentStaticConfiguration`s
@resultBuilder
public enum HTTPDependentStaticConfigurationBuilder {
    /// A method that transforms multiple `HTTPDependentStaticConfiguration`s
    ///
    /// - Parameter staticConfigurations: A variadic number of `HTTPDependentStaticConfiguration`
    ///
    /// - Returns: An `AnyConfigurationCollection` which consists of `ConfigurationConvertible`s
    public static func buildBlock(_ staticConfigurations: HTTPDependentStaticConfiguration...) -> [HTTPDependentStaticConfiguration] {
        staticConfigurations
    }
    
    
    /// A method that enables the use of standalone if statements for `HTTPDependentStaticConfiguration`s.
    ///
    /// - Parameter staticConfiguration: The `HTTPDependentStaticConfiguration` within the if statement.
    ///
    /// - Returns: Either the `HTTPDependentStaticConfiguration` within the branch if the condition evaluates to `true` or an empty array.
    public static func buildIf(_ staticConfiguration: HTTPDependentStaticConfiguration?) -> HTTPDependentStaticConfiguration {
        staticConfiguration ?? EmptyHTTPDependentStaticConfiguration()
    }
    
    
    /// A method that enables the use of if-else statements for `HTTPDependentStaticConfiguration`s
    ///
    /// - Parameter first: The `HTTPDependentStaticConfiguration` within the if statement
    ///
    /// - Returns: The `HTTPDependentStaticConfiguration` within the if statement
    public static func buildEither(first: HTTPDependentStaticConfiguration) -> HTTPDependentStaticConfiguration {
        first
    }
    
    
    /// A method that enables the use of if-else statements for `HTTPDependentStaticConfiguration`s
    ///
    /// - Parameter second: The `HTTPDependentStaticConfiguration` within the else statement
    ///
    /// - Returns: The `HTTPDependentStaticConfiguration` within the else statement
    public static func buildEither(second: HTTPDependentStaticConfiguration) -> HTTPDependentStaticConfiguration {
        second
    }
}
