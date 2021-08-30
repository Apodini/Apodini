//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public struct SummaryContextKey: OptionalContextKey {
    public typealias Value = String
}

public extension HandlerMetadataNamespace {
    typealias Summary = HandlerSummaryMetadata
}

public struct HandlerSummaryMetadata: HandlerMetadataDefinition {
    public typealias Key = SummaryContextKey

    public let value: String

    public init(_ summary: String) {
        self.value = summary
    }
}
