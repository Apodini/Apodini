//
// Created by Andreas Bauer on 22.05.21.
//

extension TypedContentMetadataNamespace {
    /// Defines a `ContentMetadataBlock` you can use to group your Relationship Metadata.
    /// See `RelationshipsContentMetadataBlock`.
    public typealias Relationships = RestrictedContentMetadataBlock<RelationshipsContentMetadataBlock>
}

/// The `RelationshipsContentMetadataBlock` can be used to structure your Relationship
/// Metadata declarations.
/// The Metadata is available under the `Relationships` name and can be used like the following:
/// ```swift
/// struct ExampleContent: Content {
///     // ...
///     static var metadata: Metadata {
///         Relationships {
///             // ...
///         }
///     }
/// }
/// ```
public class RelationshipsContentMetadataBlock: ContentMetadataDefinition {
    public typealias Key = RelationshipSourceCandidateContextKey
    
    public var value: [PartialRelationshipSourceCandidate] {
        fatalError("value getter must be overwritten")
    }
}
