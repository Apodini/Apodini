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

/// This value stores an optional closure that can be used to receive
/// forwarded `Error`s that occur during the `Endpoint` evaluation.
///
/// - Note: An instance can be obtained from any local `Blackboard`, e.g. an `Endpoint`.
public struct ErrorForwarder: OptionalContextKeyKnowledgeSource {
    public typealias Key = ErrorForwarderContextKey

    let forwardClosure: Key.Value?

    public init(from forwardClosure: Key.Value?) throws {
        self.forwardClosure = forwardClosure
    }

    /// Forward an error using the forwarders forwarding closure, if it is non-nil.
    ///
    /// - Parameter error: The error to forward.
    public func forward(_ error: Error) {
        forwardClosure?(error)
    }
}
