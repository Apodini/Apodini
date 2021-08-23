//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

/// Instead of performing authentication or authorization (like the ``Authenticator`` does)
/// an ``AuthorizationRequirementsChecker`` relies on a previously executed ``Authenticator``
/// and evaluates additional ``AuthorizationRequirement``s.
struct AuthorizationRequirementsChecker<H: Handler, Element: Authenticatable>: Handler {
    let type: AuthorizationType
    let requirements: AuthorizationRequirements<Element>

    let delegate: Delegate<H>

    @Environment(\.logger)
    var logger

    @Throws(.unauthenticated, options: .authorizationErrorReason(.authenticationRequired))
    var authenticationRequired

    @Throws(.forbidden, options: .authorizationErrorReason(.failedAuthorization))
    var failedAuthorization

    @Authorized(Element.self) var authenticatable

    init(type: AuthorizationType, _ requirements: AuthorizationRequirements<Element>, _ handler: H) {
        self.type = type
        self.requirements = requirements
        self.delegate = Delegate(handler, .required)
    }

    func handle() async throws -> H.Response {
        if !authenticatable.isAuthorized {
            switch type {
            case .optional:
                return try await delegate.instance().handle()
            case .required:
                throw authenticationRequired
            }
        }

        let result: RequirementResult
        do {
            result = try requirements.evaluate(for: try authenticatable())
        } catch {
            throw error.apodiniError(options: .authorizationErrorReason(.failedAuthorization))
        }

        switch result {
        case let .fulfilled(cause), let .undecided(cause): // undecided is a acceptance state as well!
            logger.trace("Authorization on Handler \(H.self) succeeded with \(cause())")
            return try await delegate.instance().handle()
        case let .rejected(cause):
            logger.debug("Authorization on Handler \(H.self) rejected with \(cause())")
            throw failedAuthorization
        }
    }
}

// swiftlint:disable:next type_name
struct AuthorizationRequirementsCheckerInitializer<Element: Authenticatable>: DelegatingHandlerInitializer {
    let type: AuthorizationType
    let requirements: AuthorizationRequirements<Element>

    func instance<D: Handler>(for delegate: D) throws -> SomeHandler<Never> {
        SomeHandler(AuthorizationRequirementsChecker(type: type, requirements, delegate))
    }
}
