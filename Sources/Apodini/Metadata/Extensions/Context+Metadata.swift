//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

// MARK: Metadata

public extension Context {
    /// Retrieves the value for a given `MetadataDefinition`.
    /// - Parameter contextKey: The `MetadataDefinition` to retrieve the value for.
    /// - Returns: Returns the stored value or `nil` if it does not exist on the given `Context`.
    func get<Metadata: MetadataDefinition>(valueFor metadata: Metadata.Type = Metadata.self) -> Metadata.Key.Value? {
        get(valueFor: metadata.Key.self)
    }

    /// Retrieves the value for a given `MetadataDefinition`.
    /// - Parameter contextKey: The `MetadataDefinition` to retrieve the value for.
    /// - Returns: Returns the stored value or the `ContextKey.defaultValue` if it does not exist on the given `Context`.
    func get<Metadata: MetadataDefinition>(valueFor metadata: Metadata.Type = Metadata.self) -> Metadata.Key.Value
        where Metadata.Key: ContextKey {
        get(valueFor: metadata.Key.self)
    }
}
