//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Logging

extension DecodingRequest {
    public var loggingMetadata: Logger.Metadata {
        [
            : //"parameters": .dictionary(self.parameterLoggingMetadata)
        ]
        //.merging(self.basis.loggingMetadata) { _, new in new }
        //.merging(self.input.loggingMetadata) { _, new in new }
    }
}
