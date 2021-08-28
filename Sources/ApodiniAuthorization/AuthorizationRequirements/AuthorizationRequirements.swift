//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// An ``AuthorizationRequirements`` wraps one or multiple ``AuthorizationRequirement`` instances.
/// On Evaluation it will loop over the contained requirements until the first ``RequirementResult``
/// is encountered which is not ``RequirementResult/undecided(cause:)``.
public struct AuthorizationRequirements<Element: Authenticatable>: AuthorizationRequirement {
    let requirements: [AnyAuthorizationRequirement]

    /// Initializes a new ``AuthorizationRequirements`` instance for a single ``AuthorizationRequirement``.
    /// - Parameter requirement: The ``AuthorizationRequirement`` to be wrapped.
    public init<Requirement: AuthorizationRequirement>(_ requirement: Requirement) where Requirement.Element == Element {
        self.requirements = [requirement]
    }

    init(_ container: [AuthorizationRequirements<Element>] = []) {
        self.requirements = Array(container
                                      .map { container in container.requirements }
                                      .joined())
    }

    public func evaluate(for element: Element) throws -> RequirementResult {
        if requirements.count == 1 {
            // basically a flatMap for the RequirementResult
            return try requirements[0].anyEvaluate(for: element)
        }

        var results: [RequirementResult] = []

        for requirement in requirements {
            let result = try requirement.anyEvaluate(for: element)
            results.append(result)

            switch result {
            case .undecided:
                break // continue with next requirement
            case .fulfilled:
                return .fulfilled(cause: .results(results))
            case .rejected:
                return .rejected(cause: .results(results))
            }
        }

        return .undecided(cause: .results(results))
    }
}
