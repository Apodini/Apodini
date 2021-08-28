//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

/// The ``Authorized`` property wrapper can be used to access the ``Authenticatable``
/// instance created through an authorization Metadata.
///
/// Given the example of an `ExampleUser` ``Authenticatable``, the following code may be used to
/// access the authenticated and authorized instance.
/// ```swift
/// struct ExampleHandler: Handler {
///     @Authorized(ExampleUser.self) var authorizedUser
///
///     func handle() throws -> String {
///         // you might want to use `authorizedUser.isAuthorized` if using optional authorization
///
///         let user = try authorizedUser()
///         // ...
///         return ...
///     }
/// }
/// ```
@propertyWrapper
public struct Authorized<Element: Authenticatable>: DynamicProperty {
    public var wrappedValue = AuthorizedAuthenticatable<Element>()

    public init(_: Element.Type = Element.self) {}
}

/// The wrapped value of the ``Authorized`` property wrapper. See according docs.
public struct AuthorizedAuthenticatable<Element: Authenticatable>: DynamicProperty {
    @Environment(\.authorizationStateContainer)
    private var stateContainer

    @Throws(.unauthenticated, options: .authorizationErrorReason(.authenticationRequired))
    var authenticationRequired

    /// Returns if the associated ``Element`` was successfully authenticated.
    /// This property might return false in cases of `ComponentMetadataNamespace/AuthorizeOptionally` Metadata.
    public var isAuthorized: Bool {
        stateContainer.contains(element: Element.self)
    }

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
        delegate.environment(\.authorizationStateContainer, stateContainer.inserting(instance))
    }
}

// MARK: Environment

private extension Application {
    var authorizationStateContainer: AuthorizationStateContainer {
        AuthorizationStateContainer()
    }
}


/// An ``AuthorizationStateContainer`` manages all stored ``Authenticatable`` instances stored in the environment
/// in the ``Application/authorizationStateContainer`` KeyPath.
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
