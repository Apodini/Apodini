//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import JWTKit

private struct JWTSignerKey: StorageKey {
    typealias Value = JWTSigners
}

public extension Application {
    /// Gives access to the `JWTKit.JWTSigners` configured through the ``JWTSigner`` `Configuration`.
    var jwtSigners: JWTSigners {
        if let signers = storage[JWTSignerKey.self] {
            return signers
        }

        let signers = JWTSigners()
        storage[JWTSignerKey.self] = signers
        return signers
    }
}
