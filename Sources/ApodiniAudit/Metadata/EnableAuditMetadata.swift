//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public struct EnableAuditMetadata: ComponentMetadataDefinition {
    public typealias Key = EnableAuditContextKey
    
    public let value: BestPractice.Type
}

public struct EnableAuditContextKey: OptionalContextKey {
    public typealias Value = BestPractice.Type
}
