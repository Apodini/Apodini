//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// The `AnyMetadata` protocol represents arbitrary Metadata.
/// This might be a `MetadataDefinition`, an `AnyMetadataBlock` or something else.
///
/// If you want to create new Metadata Definitions you may want to look at `MetadataDefinition`.
public protocol AnyMetadata {
    /// This method accepts the ``MetadataParser`` in order to parse the Metadata tree.
    /// The implementation should either forward the visitor to its content (e.g. in the case of a `AnyMetadataBlock`)
    /// or add the parsed Metadata to the visitor.
    ///
    /// - Parameter visitor: The ``MetadataParser`` parsing the Metadata tree.
    func collectMetadata(_ visitor: MetadataParser)
}
