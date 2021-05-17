/// A function builder used to aggregate `RelationshipDefinition`.
@resultBuilder
public enum RelationshipDefinitionBuilder {
    /// A method that transforms multiple `RelationshipDefinition`s
    public static func buildBlock(_ definitions: RelationshipDefinition...) -> [RelationshipDefinition] {
        definitions
    }
}
