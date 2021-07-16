//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
