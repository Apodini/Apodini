//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// A type conforming to ``Authenticatable`` represents state which can be authenticated and authorized
/// (using the `ApodiniAuthorization` framework).
///
/// For example this could be some sort of user model or token model.
/// A ``Authenticatable`` might be used in an ``AuthorizationMetadata`` together with an according
/// ``AuthenticationScheme`` and ``AuthenticationVerifier`` to do authentication and performing ``AuthorizationRequirement``s
/// on the given instance.
public protocol Authenticatable {}
