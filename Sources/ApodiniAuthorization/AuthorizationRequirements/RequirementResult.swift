//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// A ``RequirementResult`` represents the result of an evaluation of an ``AuthenticationRequirement``.
public enum RequirementResult {
    /// Represents a positive ``RequirementResult``.
    /// Captures the ``Cause`` leading to the result. The ``Cause`` is only captured for debug purposes.
    case fulfilled(cause: @autoclosure () -> Cause = .unspecified)
    /// Represents a neutral ``RequirementResult``.
    ///
    /// When evaluating ``AuthorizationRequirement`` evaluation will continue with the next requirement
    /// when encountering `undecided`. This is the fundamental difference to the other two cases.
    /// Although, should the final result of some ``AuthorizationRequirement`` be undecided, it is nonetheless
    /// an acceptance state. Everything which is not explicitly rejected is accepcted.
    ///
    /// Captures the ``Cause`` leading to the result. The ``Cause`` is only captured for debug purposes.
    case undecided(cause: @autoclosure () -> Cause = .unspecified)
    /// Represents a negative ``RequirementResult``.
    /// Captures the ``Cause`` leading to the result. The ``Cause`` is only captured for debug purposes.
    case rejected(cause: @autoclosure () -> Cause = .unspecified)

    /// Represents the ``Cause`` of a specific ``RequirementResult`` instance.
    public enum Cause {
        /// The result was caused by an `Error`.
        case error(_ error: Error, in: AnyAuthorizationRequirement? = nil)
        /// The result is the cause of a single ``AuthenticationRequirement``.
        case result(_ requirement: AnyAuthorizationRequirement)
        /// The result is the cause of multiple evaluations of different ``AuthenticationRequirement``s.
        case results(_ results: [RequirementResult])
        /// The cause is not specified.
        case unspecified
    }
}

extension RequirementResult: Equatable {
    public static func == (lhs: RequirementResult, rhs: RequirementResult) -> Bool {
        switch (lhs, rhs) {
        case (.fulfilled, .fulfilled),
             (.undecided, .undecided),
             (.rejected, .rejected):
            return true
        default:
            return false
        }
    }
}
