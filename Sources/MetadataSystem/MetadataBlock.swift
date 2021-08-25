//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// The `AnyMetadataBlock` protocol represents Metadata that is _somehow_ grouped together.
/// How the Metadata is grouped and how it is made accessible is the responsibility
/// of the one conforming to this protocol or of the protocol inheriting from this one.
///
/// The following Metadata Blocks are available:
/// - `HandlerMetadataBlock`
/// - `ComponentOnlyMetadataBlock`
/// - `WebServiceMetadataBlock`
/// - `ComponentMetadataBlock`
/// - `ContentMetadataBlock`
///
/// See those docs for examples on how to use them in their respective scope
/// or on how to create **independent** and thus **reusable** Metadata.
///
/// See `RestrictedMetadataBlock` for a way to create custom Metadata Blocks where
/// the content is restricted to a specific `MetadataDefinition`.
public protocol AnyMetadataBlock: AnyMetadata {
    var typeErasedContent: AnyMetadata { get }
}

public extension AnyMetadataBlock {
    /// Default implementation to visit this metadata.
    func collectMetadata(_ visitor: MetadataParser) {
        visitor._visit(block: self)
    }
}
