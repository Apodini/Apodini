//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// Defines some sort of `Context` for a given representation (like `Endpoint`).
/// A `Context` holds a collection of values for predefined `ContextKey`s or `OptionalContextKey`s.
public class Context: KnowledgeSource {
    private let entries: [ObjectIdentifier: Any]

    init(_ entries: [ObjectIdentifier: Any] = [:]) {
        self.entries = entries
    }
    
    public required init<B>(_ blackboard: B) throws where B: Blackboard {
        self.entries = blackboard[AnyEndpointSource.self].context.entries
    }

    /// Retrieves the value for a given `ContextKey`.
    /// - Parameter contextKey: The `ContextKey` to retrieve the value for.
    /// - Returns: Returns the stored value or the `ContextKey.defaultValue` if it does not exist on the given `Context`.
    public func get<C: ContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value {
        entries[ObjectIdentifier(contextKey)] as? C.Value
            ?? C.defaultValue
    }

    /// Retrieves the value for a given `OptionalContextKey`.
    /// - Parameter contextKey: The `OptionalContextKey` to retrieve the value for.
    /// - Returns: Returns the stored value or `nil` if it does not exist on the given `Context`.
    public func get<C: OptionalContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value? {
        entries[ObjectIdentifier(contextKey)] as? C.Value
    }
}

extension Context: CustomStringConvertible {
    public var description: String {
        "Context(entries: \(entries))"
    }
}
