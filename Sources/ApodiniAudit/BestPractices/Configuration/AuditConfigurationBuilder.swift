//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// A function builder used to aggregate multiple `DependentStaticConfiguration`s
@resultBuilder
public enum AuditConfigurationBuilder {
    /// Initializes all the best practices listed in `AuditInterfaceExporter.bestPractices` and returns them.
    /// If no configuration is found for a `BestPractice`, a default configuration is used.
    ///
    /// - Parameter component: The `BestPracticeConfiguration`s
    ///
    /// - Returns: An array of all `BestPracticeConfiguration`s
    public static func buildFinalResult(_ component: [BestPracticeConfiguration]) -> [BestPractice] {
        // Generate a configuration for every best practice
        var bestPracticeConfigurations = [BestPracticeConfiguration]()
        
        for conf in AuditInterfaceExporter.defaultBestPracticeConfigurations {
            // Search for a matching configuration in `component`
            let matchingConfiguration = component.first { customConf in
                type(of: customConf) == type(of: conf)
            }
            bestPracticeConfigurations.append(matchingConfiguration ?? conf)
        }
        
        return bestPracticeConfigurations.map { $0.configureBestPractice() }
    }
    
    /// A method that transforms a `BestPracticeConfiguration`
    /// into an array of a single `BestPracticeConfiguration`.
    ///
    /// - Parameter expression: The `BestPracticeConfiguration`
    ///
    /// - Returns: An array of `BestPracticeConfiguration`s
    public static func buildExpression(_ expression: BestPracticeConfiguration) -> [BestPracticeConfiguration] {
        [expression]
    }
    
    /// A method that transforms multiple `BestPracticeConfiguration`s
    ///
    /// - Parameter staticConfigurations: A variadic number of `BestPracticeConfiguration`s
    ///
    /// - Returns: An array of `AnyDependentStaticConfiguration`s
    public static func buildBlock(_ bestPracticeConfigurations: [BestPracticeConfiguration]...) -> [BestPracticeConfiguration] {
        bestPracticeConfigurations.flatMap { $0 }
    }
    
    /// A method that enables the use of if-else statements for `BestPracticeConfiguration`s
    ///
    /// - Parameter first: The `BestPracticeConfiguration` within the if statement
    ///
    /// - Returns: The `BestPracticeConfiguration` within the if statement
    public static func buildEither(first: [BestPracticeConfiguration]) -> [BestPracticeConfiguration] {
        first
    }
    
    
    /// A method that enables the use of if-else statements for `BestPracticeConfiguration`s
    ///
    /// - Parameter second: The `BestPracticeConfiguration` within the else statement
    ///
    /// - Returns: The `BestPracticeConfiguration` within the else statement
    public static func buildEither(second: [BestPracticeConfiguration]) -> [BestPracticeConfiguration] {
        second
    }
    
    /// A method that enables the use of if statements for `BestPracticeConfiguration`s
    ///
    /// - Parameter component: The `BestPracticeConfiguration` within if statement
    ///
    /// - Returns: The `BestPracticeConfiguration` within the if statement if the condition is true, nil otherwise
    public static func buildOptional(_ component: [BestPracticeConfiguration]?) -> [BestPracticeConfiguration] {
        // swiftlint:disable:previous discouraged_optional_collection
        component ?? []
    }
}
