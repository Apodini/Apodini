//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniContext

public protocol EmptyMetadata: MetadataDefinition where Key == Never {}

public extension EmptyMetadata {
    /// Empty metadata cannot have a value.
    var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }
}
