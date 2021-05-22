//
// Created by Andreas Bauer on 22.05.21.
//

// TODO we use typed below as anything else uses typed as well
extension TypedContentMetadataNamespace {
    /// Defines a `ContentMetadataGroup` you can use to group your Relationship Metadata.
    /// See `RelationshipsContentMetadataGroup`.
    public typealias Relationships = RestrictedContentMetadataGroup<RelationshipsContentMetadataGroup>
}

// TODO docs
public class RelationshipsContentMetadataGroup: ContentMetadataDefinition {
    public typealias Key = RelationshipSourceCandidateContextKey
    
    public var value: [PartialRelationshipSourceCandidate] {
        fatalError("value getter must be overwritten")
    }
}
