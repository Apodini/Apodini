//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public struct ErrorForwarderContextKey: OptionalContextKey {
    public typealias Value = (Error) -> Void
}

public struct ErrorForwarder: OptionalContextKeyKnowledgeSource {
    public typealias Key = ErrorForwarderContextKey

    let forward: Key.Value?

    public init(from forward: Key.Value?) throws {
        self.forward = forward
    }
}
