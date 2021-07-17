//
// Created by Andreas Bauer on 16.07.21.
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

    let authenticatable: Authorized<Element> = .init()

    init(type: AuthorizationType, _ requirements: AuthorizationRequirements<Element>, _ handler: H) {
        self.type = type
        self.requirements = requirements
        self.delegate = Delegate(handler, .required)
    }

    func handle() async throws -> H.Response {
        if !authenticatable.isAuthorized {
            switch type {
            case .optional:
                return await try delegate.instance().handle()
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
            return await try delegate.instance().handle()
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
