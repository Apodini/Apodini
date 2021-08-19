//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniAuthorization
import JWTKit

public extension ConditionalAuthorizationRequirement {
    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the JWT `BoolClaim` property
    /// pointed to by the `KeyPath` holds the value `true`.
    /// - Parameter boolKeyPath: The `KeyPath`.
    init(if boolKeyPath: KeyPath<Element, BoolClaim>) {
        self.init { element in element[keyPath: boolKeyPath].value }
    }

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the JWT `BoolClaim` property
    /// pointed to by the `KeyPath` holds the value `false`.
    /// - Parameter boolKeyPath: The `KeyPath`.
    init(ifNot boolKeyPath: KeyPath<Element, BoolClaim>) {
        self.init { element in !element[keyPath: boolKeyPath].value }
    }
}

public extension Verify {
    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the JWT `BoolClaim` property
    /// pointed to by the `KeyPath` holds the value `true`.
    /// - Parameter boolKeyPath: The `KeyPath`.
    init(that boolKeyPath: KeyPath<Element, BoolClaim>) {
        self.init(if: boolKeyPath)
    }

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the JWT `BoolClaim` property
    /// pointed to by the `KeyPath` holds the value `false`.
    /// - Parameter boolKeyPath: The `KeyPath`.
    init(not boolKeyPath: KeyPath<Element, BoolClaim>) {
        self.init(ifNot: boolKeyPath)
    }
}
