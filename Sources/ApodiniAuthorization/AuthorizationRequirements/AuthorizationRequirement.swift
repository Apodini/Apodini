//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// An ``AuthorizationRequirement`` represents some sort of Authorization Requirement which is
/// evaluated against a certain ``Authenticatable`` instance.
public protocol AuthorizationRequirement: AnyAuthorizationRequirement {
    /// The ``Authenticatable`` element, the requirement is evaluated against.
    associatedtype Element: Authenticatable

    /// Evaluates the ``AuthorizationRequirement`` against a certain ``Authenticatable`` instance.
    ///
    /// - Parameter element: The ``Authenticatable`` instances for which the requirement should be evaluated.
    /// - Returns: Returns a ``RequirementResult``.
    /// - Throws: Throws an ``ApodiniError`` if necessary. While throwing is allowed, any expected errors
    ///     should ideally be transformed into a ``RequirementResult`` using the ``RequirementResult/Cause/error`` cause.
    func evaluate(for element: Element) throws -> RequirementResult
}
