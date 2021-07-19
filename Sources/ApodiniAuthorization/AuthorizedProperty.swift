//
// Created by Andreas Bauer on 11.07.21.
//

import Apodini

/// The ``Authorized`` `DynamicProperty` can be used to access the ``Authenticatable``
/// instance created through a authorization Metadata.
///
/// Given the example of an `ExampleUser` ``Authenticatable``, the following code may be used to
/// access the authenticated and authorized instance.
/// ```swift
/// struct ExampleHandler: Handler {
///     var authorizedUser = Authorized<ExampleUser>()
///
///     func handle() -> String {
///         // you might want to use `authorizedUser.isAuthorized` if using optional authorization
///
///         let user = try authorizedUser()
///         // ...
///         return ...
///     }
/// }
/// ```
public struct Authorized<Element: Authenticatable>: DynamicProperty {
    @Environment(\.wrapped.stateContainer)
    private var stateContainer

    @Throws(.unauthenticated, options: .authorizationErrorReason(.authenticationRequired))
    var authenticationRequired

    /// Returns if the associated ``Element`` was successfully authenticated.
    /// This property might return false in cases of ``ComponentMetadataNamespace/AuthorizeOptionally`` Metadata.
    public var isAuthorized: Bool {
        stateContainer.contains(element: Element.self)
    }

    public init(_: Element.Type = Element.self) {}

    /// Returns the ``Authenticatable`` instance.
    /// - Returns: The ``Authenticatable`` instance.
    /// - Throws: Might throw an `ApodiniError` in cases where an authorized ``Element`` instance
    ///     could not be found.
    @discardableResult
    public func callAsFunction() throws -> Element {
        guard let element: Element = stateContainer.retrieve() else {
            // throws an error because the user requires the Authenticatable to be present, but it isn't.
            // The error is forwarded to the AuthenticationScheme.mapFailedAuthorization(failedWith:).
            throw authenticationRequired
        }

        return element
    }

    func store<H: Handler>(into delegate: Delegate<H>, instance: Element? = nil) -> Delegate<H> {
        delegate.environment(\.wrapped.stateContainer, stateContainer.inserting(instance))
    }
}

// MARK: Environment

private extension Application {
    class WrappedContainer {
        var stateContainer = AuthorizationStateContainer()
    }

    var wrapped: WrappedContainer {
        WrappedContainer()
    }
}

/// The ``SomeAuthorizationStateContainer`` type is a type erasing wrapper around an ``AuthorizationStateContainer``
private struct AuthorizationStateContainer {
    let storedElements: [ObjectIdentifier: Authenticatable]

    init(_ elements: [ObjectIdentifier: Authenticatable] = [:]) {
        storedElements = elements
    }

    init<Element: Authenticatable>(_ element: Element) {
        storedElements = [ObjectIdentifier(Element.self): element]
    }

    func inserting<Element: Authenticatable>(_ element: Element?) -> Self {
        guard let element = element else {
            return self
        }

        let id = ObjectIdentifier(Element.self)
        if let existing = storedElements[id] {
            fatalError("""
                       AuthorizationStateContainer tried setting Authenticatable instance although one was already present! \
                       Existing: \(existing); New: \(element).
                       """)
        }

        var storedElements = self.storedElements
        storedElements[id] = element
        return AuthorizationStateContainer(storedElements)
    }

    func contains<Element: Authenticatable>(element: Element.Type) -> Bool {
        storedElements[ObjectIdentifier(element)] != nil
    }

    func retrieve<Element: Authenticatable>(_ type: Element.Type = Element.self) -> Element? {
        guard let authenticatable = storedElements[ObjectIdentifier(Element.self)] else {
            return nil
        }
        guard let element = authenticatable as? Element else {
            fatalError("Reached data inconsistency. ObjectIdentifier didn't point to expected type.")
        }

        return element
    }
}
