//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation

/// A helper protocol that provides typed access to the `Handler` stored in `AnyEndpointSource`.
public protocol HandlerKnowledgeSource: KnowledgeSource {
    init<H: Handler, B: Blackboard>(from handler: H, _ blackboard: B) throws
}

extension HandlerKnowledgeSource {
    /// Calls `HandlerKnowledgeSource.init` using the `Handler` extracted from `AnyEndpointSource`.
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        let anyEndpointSource = blackboard[AnyEndpointSource.self]
        
        self = try anyEndpointSource.create(Self.self, using: blackboard)
    }
}
