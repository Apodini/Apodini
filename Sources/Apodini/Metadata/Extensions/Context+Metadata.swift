//
// Created by Andreas Bauer on 19.06.21.
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
