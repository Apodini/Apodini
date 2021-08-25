//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

public protocol WrappedMetadataDefinition: AnyMetadata {
    associatedtype Metadata: MetadataDefinition

    var metadata: Metadata { get }
}

public extension WrappedMetadataDefinition {
    /// Default implementation to visit this metadata.
    func collectMetadata(_ visitor: MetadataParser) {
        visitor.visit(wrapped: self)
    }
}
