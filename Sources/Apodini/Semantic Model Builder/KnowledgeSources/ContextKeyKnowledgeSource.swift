//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation


public protocol OptionalContextKeyKnowledgeSource: KnowledgeSource {
    /// The `OptionalContextKey` used to identify the value.
    associatedtype Key: OptionalContextKey
    /// Initializes the `KnowledgeSource` based on the `Key`'s value in the `Context`
    /// associated with the underlying `Blackboard`.
    init(from value: Key.Value?) throws
}

extension OptionalContextKeyKnowledgeSource {
    /// Calls `OptionalContextKeyKnowledgeSource.init` using the value stored in `AnyEndpointSource`.
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        try self.init(from: blackboard[AnyEndpointSource.self].context.get(valueFor: Key.self))
    }
}

public protocol ContextKeyKnowledgeSource: OptionalContextKeyKnowledgeSource where Key: ContextKey {
    /// Initializes the `KnowledgeSource` based on the `Key`'s value in the `Context`
    /// associated with the underlying `Blackboard`.
    init(from value: Key.Value) throws
}

extension ContextKeyKnowledgeSource {
    /// Calls `ContextKeyKnowledgeSource.init` using the value stored in `AnyEndpointSource` or uses
    /// the `Key`'s `defaultValue`.
    public init(from value: Key.Value?) throws {
        try self.init(from: value ?? Key.defaultValue)
    }
}
