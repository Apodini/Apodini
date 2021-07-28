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
    static func buildExpression<Metadata: ComponentMetadataDefinition>(_ expression: Metadata) -> AnyComponentMetadata {
        WrappedComponentMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: ComponentMetadataBlock>(_ expression: Metadata) -> AnyComponentMetadata {
        expression
    }

    static func buildOptional(_ component: AnyComponentMetadata?) -> AnyComponentMetadata {
        component ?? EmptyComponentMetadata()
    }

    static func buildEither(first: AnyComponentMetadata) -> AnyComponentMetadata {
        first
    }

    static func buildEither(second: AnyComponentMetadata) -> AnyComponentMetadata {
        second
    }

    static func buildArray(_ components: [AnyComponentMetadata]) -> AnyComponentMetadata {
        AnyComponentMetadataArrayWrapper(components)
    }

    static func buildBlock(_ components: AnyComponentMetadata...) -> AnyComponentMetadata {
        AnyComponentMetadataArrayWrapper(components)
    }
}
