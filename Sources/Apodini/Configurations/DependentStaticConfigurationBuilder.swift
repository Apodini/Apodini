//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// A function builder used to aggregate multiple `DependentStaticConfiguration`s
@resultBuilder
public enum DependentStaticConfigurationBuilder<InternalParentConfiguration> {
    /// A method that transforms a `DependentStaticConfiguration` with the required `InteralParentConfiguration`
    /// into an array of a single `AnyDependentStaticConfiguration`.
    ///
    /// - Parameter expression: The `DependentStaticConfiguration`
    ///
    /// - Returns: An array of `AnyDependentStaticConfiguration`s
    public static func buildExpression<T: DependentStaticConfiguration>(_ expression: T) -> [AnyDependentStaticConfiguration]
        where T.InternalParentConfiguration == InternalParentConfiguration {
        [expression]
    }
    
    /// A method that transforms multiple `AnyDependentStaticConfiguration`s
    ///
    /// - Parameter staticConfigurations: A variadic number of `AnyDependentStaticConfiguration`
    ///
    /// - Returns: An array of `AnyDependentStaticConfiguration`s
    public static func buildBlock(_ staticConfigurations: [AnyDependentStaticConfiguration]...) -> [AnyDependentStaticConfiguration] {
        staticConfigurations.flatMap { $0 }
    }
    
    /// A method that enables the use of if-else statements for `AnyDependentStaticConfiguration`s
    ///
    /// - Parameter first: The `AnyDependentStaticConfiguration` within the if statement
    ///
    /// - Returns: The `AnyDependentStaticConfiguration` within the if statement
    public static func buildEither(first: [AnyDependentStaticConfiguration]) -> [AnyDependentStaticConfiguration] {
        first
    }
    
    
    /// A method that enables the use of if-else statements for `AnyDependentStaticConfiguration`s
    ///
    /// - Parameter second: The `AnyDependentStaticConfiguration` within the else statement
    ///
    /// - Returns: The `AnyDependentStaticConfiguration` within the else statement
    public static func buildEither(second: [AnyDependentStaticConfiguration]) -> [AnyDependentStaticConfiguration] {
        second
    }
    
    /// A method that enables the use of if statements for `AnyDependentStaticConfiguration`s
    ///
    /// - Parameter component: The `AnyDependentStaticConfiguration` within if statement
    ///
    /// - Returns: The `AnyDependentStaticConfiguration` within the if statement if the condition is true, an empty array otherwise
    // swiftlint:disable discouraged_optional_collection
    public static func buildOptional(_ component: [AnyDependentStaticConfiguration]?) -> [AnyDependentStaticConfiguration] {
        component ?? []
    }
}
