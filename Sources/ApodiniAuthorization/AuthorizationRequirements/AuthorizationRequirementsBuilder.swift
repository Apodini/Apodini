//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// Builds ``AuthorizationRequirement``s.
@resultBuilder
public enum AuthorizationRequirementsBuilder<Element: Authenticatable> {
    /// Builds the ``AuthorizationRequirements`` component for a single ``AuthorizationRequirement`` expression.
    public static func buildExpression<Requirement: AuthorizationRequirement>(_ expression: Requirement) -> AuthorizationRequirements<Element>
        where Requirement.Element == Element {
        AuthorizationRequirements(expression)
    }

    /// Builds a block of ``AuthorizationRequirements`` components.
    public static func buildBlock(_ components: AuthorizationRequirements<Element>...) -> AuthorizationRequirements<Element> {
        AuthorizationRequirements(components)
    }

    /// Builds the first of a ``AuthorizationRequirements`` either block.
    public static func buildEither(first component: AuthorizationRequirements<Element>) -> AuthorizationRequirements<Element> {
        component
    }

    /// Builds the second of a ``AuthorizationRequirements`` either block.
    public static func buildEither(second component: AuthorizationRequirements<Element>) -> AuthorizationRequirements<Element> {
        component
    }

    /// Builds an array of ``AuthorizationRequirements``.
    public static func buildArray(_ components: [AuthorizationRequirements<Element>]) -> AuthorizationRequirements<Element> {
        AuthorizationRequirements(components)
    }

    /// Builds an optional ``AuthorizationRequirements``.
    public static func buildOptional(_ component: AuthorizationRequirements<Element>?) -> AuthorizationRequirements<Element> {
        if let component = component {
            return AuthorizationRequirements(component)
        }
        return AuthorizationRequirements()
    }
}
