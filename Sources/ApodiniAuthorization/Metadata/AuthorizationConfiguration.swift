//
// Created by Andreas Bauer on 09.07.21.
//

import Apodini

/// Defines the type of a Authorization Metadata.
enum AuthorizationType {
    case required
    case optional
}

// MARK: Optionality
extension AuthorizationType {
    var optionality: Optionality {
        switch self {
        case .required:
            return .required
        case .optional:
            return .optional
        }
    }
}

/// A instance conforming to ``AuthorizationConfiguration`` presents the data required to configure a ``DatabaseAuthenticator``
/// This is basically a way to easily pass around the configuration without the need to repeat the where clause.
protocol AuthorizationConfiguration where Scheme.AuthenticationInfo == Verifier.AuthenticationInfo, Verifier.Element == Authenticatable {
    associatedtype Scheme: AuthenticationScheme
    associatedtype Verifier: AuthenticationVerifier
    associatedtype Authenticatable

    var type: AuthorizationType { get }
    var scheme: Scheme { get }
    var verifier: Verifier { get }
    var authenticatable: Authenticatable.Type { get }
    var skipRequirementsForAuthorized: Bool { get }
}

struct StandardAuthenticatorConfiguration<Scheme: AuthenticationScheme, Verifier: AuthenticationVerifier, Authenticatable>: AuthorizationConfiguration
    where Scheme.AuthenticationInfo == Verifier.AuthenticationInfo, Verifier.Element == Authenticatable {
    var type: AuthorizationType
    var scheme: Scheme
    var verifier: Verifier
    var authenticatable: Authenticatable.Type
    var skipRequirementsForAuthorized: Bool
}
