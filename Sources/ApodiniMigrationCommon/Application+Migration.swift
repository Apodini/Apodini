//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2022 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

private struct ApodiniMigrationKey: StorageKey {
    typealias Value = ApodiniMigrationContext
}

extension Application {
    /// Gives access to the global ``ApodiniMigrationContext`` which is used to exchange
    /// information between ApodiniMigration supporting exporters and the `ApodiniMigrationInterfaceExporter`.
    public var apodiniMigration: ApodiniMigrationContext {
        guard let context = storage[ApodiniMigrationKey.self] else {
            let context = ApodiniMigrationContext()
            storage[ApodiniMigrationKey.self] = context
            return context
        }
        return context
    }
}
