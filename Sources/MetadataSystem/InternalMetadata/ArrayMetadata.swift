//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// An ``AnyMetadataArray`` represents a wrapper around an array of type erased Metadata.
/// For every kind of Metadata you need to define your MetadataArray (used in the result builder)
public protocol AnyMetadataArray: AnyMetadata {
    associatedtype Element = AnyMetadata

    var array: [Element] { get }
}

public extension AnyMetadataArray {
    /// Returns the type erased metadata content of the ``AnyMetadataBlock``.
    var anyMetadata: AnyMetadata {
        self
    }

    /// Default implementation to visit this metadata.
    func collectMetadata(_ visitor: MetadataParser) {
        visitor.visit(array: self)
    }
}
