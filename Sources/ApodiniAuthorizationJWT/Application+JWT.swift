//
// Created by Andreas Bauer on 15.07.21.
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
