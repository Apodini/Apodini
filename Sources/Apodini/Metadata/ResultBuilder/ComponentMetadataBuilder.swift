//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

// swiftlint:disable missing_docs


@resultBuilder
public enum ComponentMetadataBuilder {}

public extension ComponentMetadataBuilder {
    static func buildExpression<Metadata: ComponentMetadataDefinition>(_ expression: Metadata) -> any AnyComponentMetadata {
        WrappedComponentMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: ComponentMetadataBlock>(_ expression: Metadata) -> any AnyComponentMetadata {
        expression
    }

    static func buildOptional(_ component: (any AnyComponentMetadata)?) -> any AnyComponentMetadata {
        component ?? EmptyComponentMetadata()
    }

    static func buildEither(first: any AnyComponentMetadata) -> any AnyComponentMetadata {
        first
    }

    static func buildEither(second: any AnyComponentMetadata) -> any AnyComponentMetadata {
        second
    }

    static func buildArray(_ components: [any AnyComponentMetadata]) -> any AnyComponentMetadata {
        AnyComponentMetadataArray(components)
    }

    static func buildBlock(_ components: any AnyComponentMetadata...) -> any AnyComponentMetadata {
        AnyComponentMetadataArray(components)
    }
}
