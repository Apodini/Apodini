//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// A ``RestrictedMetadataBlock`` is a  ``AnyMetadataBlock`` which is restricted to only contain
/// a specific Type of ``AnyMetadata`` (``RestrictedMetadataBlock``s support arbitrary nesting, meaning
/// they always can contain themselves).
///
/// In order to support multiple ``AnyMetadata`` which is allowed inside a ``RestrictedMetadataBlock``,
/// use a class as the base Metadata type, creating subclasses for all allowed Metadata.
public protocol RestrictedMetadataBlock: AnyMetadataBlock {
    associatedtype RestrictedContent: AnyMetadata
}
