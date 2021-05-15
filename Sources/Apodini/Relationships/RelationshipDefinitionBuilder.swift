/// A function builder used to aggregate `RelationshipDefinition`.
#if swift(>=5.4)
@resultBuilder
public enum RelationshipDefinitionBuilder {}
#else
@_functionBuilder
public enum RelationshipDefinitionBuilder {}
#endif
extension RelationshipDefinitionBuilder {
    /// A method that transforms multiple `RelationshipDefinition`s
    public static func buildBlock(_ definitions: RelationshipDefinition...) -> [RelationshipDefinition] {
        definitions
    }
}
