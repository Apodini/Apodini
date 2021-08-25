//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

struct WrappedHandlerMetadataDefinition<Metadata: HandlerMetadataDefinition>: WrappedMetadataDefinition, AnyHandlerMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }
}

struct WrappedComponentOnlyMetadataDefinition<Metadata: ComponentOnlyMetadataDefinition>: WrappedMetadataDefinition, AnyComponentOnlyMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }
}

struct WrappedWebServiceMetadataDefinition<Metadata: WebServiceMetadataDefinition>: WrappedMetadataDefinition, AnyWebServiceMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }
}

struct WrappedComponentMetadataDefinition<Metadata: ComponentMetadataDefinition>: WrappedMetadataDefinition, AnyComponentMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }
}

struct WrappedContentMetadataDefinition<Metadata: ContentMetadataDefinition>: WrappedMetadataDefinition, AnyContentMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }
}
