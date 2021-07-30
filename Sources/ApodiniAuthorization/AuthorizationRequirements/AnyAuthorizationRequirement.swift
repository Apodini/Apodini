//
// Created by Andreas Bauer on 09.07.21.
//

/// Represents a type erased ``AuthorizationRequirement``
public protocol AnyAuthorizationRequirement {
    /// Evaluates the ``AnyAuthorizationRequirement`` on a non fixed ``Authenticatable`` instance.
    ///
    /// Note, the Element generic must match the ``AuthorizationRequirement/Element`` when called, even when
    /// not enforced by the type checker.
    /// The method is implemented by default when conforming to ``AuthorizationRequirement``.
    ///
    /// - Parameter element: The ``Authenticatable`` instances for which the requirement should be evaluated.
    /// - Returns: Returns a ``RequirementResult``.
    /// - Throws: Throws an ``ApodiniError`` if necessary. While throwing is allowed, any expected errors
    ///     should ideally be transformed into a ``RequirementResult`` using the ``RequirementResult/Cause/error`` cause.
    func anyEvaluate<Element: Authenticatable>(for element: Element) throws -> RequirementResult
}

// MARK: AnyAuthorizationRequirement
public extension AuthorizationRequirement {
    /// Default implementation calling the typed evaluate version.
    func anyEvaluate<E: Authenticatable>(for element: E) throws -> RequirementResult {
        guard let element = element as? Element else {
            fatalError("Received invalid type \(E.self) when expecting \(Element.self)")
        }

        return try evaluate(for: element)
    }
}
