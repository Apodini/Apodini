//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// A function builder used to aggregate multiple `DependentStaticConfiguration`s
@resultBuilder
public enum DependentStaticConfigurationBuilder<ParentConfiguration: ConfigurationWithDependents> {
    
    /// A method that transforms multiple `DependentStaticConfiguration`s
    ///
    /// - Parameter staticConfigurations: A variadic number of `DependentStaticConfiguration`
    ///
    /// - Returns: An `AnyConfigurationCollection` which consists of `ConfigurationConvertible`s
    public static func buildBlock(_ staticConfigurations: [AnyDependentStaticConfiguration]...) -> [AnyDependentStaticConfiguration] {
        staticConfigurations.flatMap { $0 }
    }
    
    /// A method that enables the use of if-else statements for `DependentStaticConfiguration`s
    ///
    /// - Parameter first: The `DependentStaticConfiguration` within the if statement
    ///
    /// - Returns: The `DependentStaticConfiguration` within the if statement
    public static func buildEither(first: [AnyDependentStaticConfiguration]) -> [AnyDependentStaticConfiguration] {
        first
    }
    
    
    /// A method that enables the use of if-else statements for `DependentStaticConfiguration`s
    ///
    /// - Parameter second: The `DependentStaticConfiguration` within the else statement
    ///
    /// - Returns: The `DependentStaticConfiguration` within the else statement
    public static func buildEither(second: [AnyDependentStaticConfiguration]) -> [AnyDependentStaticConfiguration] {
        second
    }
    
    public static func buildExpression<T: DependentStaticConfiguration>(_ expression: T) -> [AnyDependentStaticConfiguration] where T.ParentConfiguration == ParentConfiguration {
        [expression]
    }
    
    public static func buildOptional(_ component: [AnyDependentStaticConfiguration]?) -> [AnyDependentStaticConfiguration] {
        component ?? []
    }
}
