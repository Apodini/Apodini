//
// Created by Andreas Bauer on 09.07.21.
//

/// A ``RequirementResult`` represents the result of an evaluation of an ``AuthenticationRequirement``.
public enum RequirementResult {
    /// Represents a positive ``RequirementResult``.
    /// Captures the ``Cause`` leading to the result. The ``Cause`` is only captured for debug purposes.
    case fulfilled(cause: @autoclosure () -> Cause = .unspecified)
    /// Represents a neutral ``RequirementResult``.
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
        /// The result is the cause of multiple evaluations of different ``AuthenticationRequirement``.
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
