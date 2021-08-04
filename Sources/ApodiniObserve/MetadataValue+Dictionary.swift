//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Logging

/// Extension that allows easy access to the `.dictionary`case of the `Logger.Metadata`
public extension Logger.MetadataValue {
    /// A computed property that allows easy access to the `.dictionary`case of the ``Logger.Metadata``
    var metadataDictionary: Logger.Metadata {
        switch self {
        case .dictionary(let dictionary):
            return dictionary
        default: return [:]
        }
    }
}
