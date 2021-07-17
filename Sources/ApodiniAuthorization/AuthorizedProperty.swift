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

    private var environmentValue: AuthorizationStateContainer<Element> {
        stateContainer.retrieve(Element.self)
    }

    @Throws(.unauthenticated, options: .authorizationErrorReason(.authenticationRequired))
    var authenticationRequired

    /// Returns if the associated ``Element`` was successfully authenticated.
    /// This property might return false in cases of ``ComponentMetadataNamespace/AuthorizeOptionally`` Metadata.
    public var isAuthorized: Bool {
        environmentValue.element != nil
    }

    public init(_: Element.Type = Element.self) {}

    /// Returns the ``Authenticatable`` instance.
    /// - Returns: The ``Authenticatable`` instance.
    /// - Throws: Might throw an `ApodiniError` in cases where an authorized ``Element`` instance
    ///     could not be found.
    public func callAsFunction() throws -> Element {
        guard let element = environmentValue.element else {
            // throws an error because the user requires the Authenticatable to be present, but it isn't.
            // The error is forwarded to the AuthenticationScheme.mapFailedAuthorization(failedWith:).
            // Either use the potentialError created by a `AuthorizeOptionally` Metadata or create a custom one.
            // See docs of `AuthorizationStateContainer/potentialError`
            throw environmentValue.potentialError ?? authenticationRequired
        }

        return element
    }

    func store<H: Handler>(into delegate: Delegate<H>, instance: Element) -> Delegate<H> {
        delegate.environment(\.wrapped.stateContainer, SomeAuthorizationStateContainer(environmentValue(instance)))
    }

    func store<H: Handler>(into delegate: Delegate<H>, potentialError: ApodiniError) -> Delegate<H> {
        delegate.environment(\.wrapped.stateContainer, SomeAuthorizationStateContainer(environmentValue(potentialError: potentialError)))
    }
}

// MARK: Environment

/// ``AnyStateContainer`` represents a type erased ``AuthorizationStateContainer``
private protocol AnyStateContainer {}
extension AuthorizationStateContainer: AnyStateContainer {}


/// The ``SomeAuthorizationStateContainer`` type is a type erasing wrapper around an ``AuthorizationStateContainer``
private struct SomeAuthorizationStateContainer {
    let wrappedContainer: (id: ObjectIdentifier, container: AnyStateContainer)?

    init() {
        wrappedContainer = nil
    }

    init<Element: Authenticatable>(_ container: AuthorizationStateContainer<Element>) {
        wrappedContainer = (ObjectIdentifier(Element.self), container)
    }

    func retrieve<Element: Authenticatable>(_ type: Element.Type = Element.self) -> AuthorizationStateContainer<Element> {
        guard let containerTuple = wrappedContainer,
              containerTuple.id == ObjectIdentifier(type),
              let container = containerTuple.container as? AuthorizationStateContainer<Element> else {
            return AuthorizationStateContainer()
        }

        return container
    }
}

private extension Application {
    class WrappedContainer {
        var stateContainer = SomeAuthorizationStateContainer()
    }

    var wrapped: WrappedContainer {
        WrappedContainer()
    }
}
