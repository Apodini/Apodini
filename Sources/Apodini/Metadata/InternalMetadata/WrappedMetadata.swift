//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
struct WrappedHandlerMetadataDefinition<Metadata: HandlerMetadataDefinition>: AnyHandlerMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedComponentOnlyMetadataDefinition<Metadata: ComponentOnlyMetadataDefinition>: AnyComponentOnlyMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedWebServiceMetadataDefinition<Metadata: WebServiceMetadataDefinition>: AnyWebServiceMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedComponentMetadataDefinition<Metadata: ComponentMetadataDefinition>: AnyComponentMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedContentMetadataDefinition<Metadata: ContentMetadataDefinition>: AnyContentMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}
