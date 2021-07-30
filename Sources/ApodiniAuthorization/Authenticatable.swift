//
// Created by Andreas Bauer on 07.07.21.
//

/// A type conforming to ``Authenticatable`` represents state which can be authenticated and authorized
/// (using the `ApodiniAuthorization` framework).
///
/// For example this could be some sort of user model or token model.
/// A ``Authenticatable`` might be used in an ``AuthorizationMetadata`` together with an according
/// ``AuthenticationScheme`` and ``AuthenticationVerifier`` to do authentication and performing ``AuthorizationRequirement``s
/// on the given instance.
public protocol Authenticatable {}
