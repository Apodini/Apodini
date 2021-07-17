//
// Created by Andreas Bauer on 03.07.21.
//

import Apodini

/// The ``Authenticator`` is the core Delegating Handler which orchestrates authentication and authorization.
struct Authenticator<H: Handler, Configuration: AuthorizationConfiguration>: Handler {
    let type: AuthorizationType
    let scheme: Delegate<Configuration.Scheme>
    let verifier: Delegate<Configuration.Verifier>
    let requirements: AuthorizationRequirements<Configuration.Authenticatable>

    /// The `Delegate` to forward execution once done.
    let delegate: Delegate<H>

    @Environment(\.logger)
    var logger

    @Throws(.unauthenticated, options: .authorizationErrorReason(.authenticationRequired))
    var authenticationRequired

    @Throws(.forbidden, options: .authorizationErrorReason(.failedAuthorization))
    var failedAuthorization

    let authenticatable: Authorized<Configuration.Authenticatable> = .init()

    init(_ configuration: Configuration, _ requirements: AuthorizationRequirements<Configuration.Authenticatable>, _ handler: H) {
        self.type = configuration.type
        self.scheme = Delegate(configuration.scheme, type.optionality)
        self.verifier = Delegate(configuration.verifier, type.optionality)
        self.requirements = requirements
        self.delegate = Delegate(handler, .required)
    }

    func handle() async throws -> H.Response {
        if authenticatable.isAuthorized {
            return try await delegate.instance().handle()
        }

        let authenticationScheme = try self.scheme.instance()

        do {
            return try await authenticationAndAuthorize(scheme: authenticationScheme)
        } catch {
            // Map any error containing a `AuthorizationErrorReason` option using `mapFailedAuthorization`
            guard error.apodiniError.option(for: .authorizationErrorReason) != nil else {
                throw error
            }

            logger.trace("Authorization on Handler \(H.self) failed with \(error)")

            throw authenticationScheme.mapFailedAuthorization(failedWith: error.apodiniError)
        }
    }

    func authenticationAndAuthorize(scheme: Configuration.Scheme) async throws -> H.Response {
        let maybeAuthenticationInfo: Configuration.Scheme.AuthenticationInfo?
        do {
            maybeAuthenticationInfo = try scheme.deriveAuthenticationInfo()
        } catch {
            throw error.apodiniError(options: .authorizationErrorReason(.invalidAuthenticationRequest))
        }

        guard let authenticationInfo = maybeAuthenticationInfo else {
            switch type {
            case .required:
                throw authenticationRequired
            case .optional:
                // found no authentication information and it isn't required. Create an appropriate error
                // and save it into the environment value. See `AuthorizationStateContainer/potentialError`.
                return try await delegate
                    .environmentObject(authenticatable.environmentValue(potentialError: authenticationRequired))
                    .instance()
                    .handle()
            }
        }

        let verifier = try self.verifier.instance()

        let instance: Configuration.Authenticatable
        do {
            instance = try verifier.initializeAndVerify(for: authenticationInfo)
        } catch {
            throw error.apodiniError(options: .authorizationErrorReason(.failedAuthentication))
        }

        let result: RequirementResult
        do {
            result = try requirements.evaluate(for: instance)
        } catch {
            throw error.apodiniError(options: .authorizationErrorReason(.failedAuthorization))
        }

        switch result {
        case let .fulfilled(cause), let .undecided(cause): // undecided is a acceptance state as well!
            logger.trace("Authorization on Handler \(H.self) succeeded with \(cause())")
            return try await delegate
                .environmentObject(authenticatable.environmentValue(instance))
                .instance()
                .handle()
        case let .rejected(cause):
            logger.debug("Authorization on Handler \(H.self) rejected with \(cause())")
            throw failedAuthorization
        }
    }
}

struct AuthenticatorInitializer<Configuration: AuthorizationConfiguration>: DelegatingHandlerInitializer {
    let configuration: Configuration
    let requirements: AuthorizationRequirements<Configuration.Authenticatable>

    init(_ configuration: Configuration, _ requirements: AuthorizationRequirements<Configuration.Authenticatable>) {
        self.configuration = configuration
        self.requirements = requirements
    }

    func instance<D: Handler>(for delegate: D) throws -> SomeHandler<Never> {
        SomeHandler(Authenticator(configuration, requirements, delegate))
    }
}
