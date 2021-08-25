//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//  

// swiftlint:disable missing_docs


@resultBuilder
public enum RestrictedMetadataBlockBuilder<Block: RestrictedMetadataBlock> {}

// MARK: Restricted Handler Metadata Block
public extension RestrictedMetadataBlockBuilder where Block: HandlerMetadataBlock, Block.RestrictedContent: AnyHandlerMetadata {
    static func buildExpression(_ expression: Block.RestrictedContent) -> AnyHandlerMetadata {
        expression
    }

    static func buildExpression(_ expression: Block) -> AnyHandlerMetadata {
        expression
    }

    static func buildOptional(_ component: AnyHandlerMetadata?) -> AnyHandlerMetadata {
        component ?? EmptyHandlerMetadata()
    }

    static func buildEither(first: AnyHandlerMetadata) -> AnyHandlerMetadata {
        first
    }

    static func buildEither(second: AnyHandlerMetadata) -> AnyHandlerMetadata {
        second
    }

    static func buildArray(_ components: [AnyHandlerMetadata]) -> AnyHandlerMetadata {
        AnyHandlerMetadataArray(components)
    }

    static func buildBlock(_ components: AnyHandlerMetadata...) -> AnyHandlerMetadata {
        AnyHandlerMetadataArray(components)
    }
}

// MARK: Restricted Component-Only Metadata Block
public extension RestrictedMetadataBlockBuilder where Block: ComponentOnlyMetadataBlock, Block.RestrictedContent: AnyComponentOnlyMetadata {
    static func buildExpression(_ expression: Block.RestrictedContent) -> AnyComponentOnlyMetadata {
        expression
    }

    static func buildExpression(_ expression: Block) -> AnyComponentOnlyMetadata {
        expression
    }

    static func buildOptional(_ component: AnyComponentOnlyMetadata?) -> AnyComponentOnlyMetadata {
        component ?? EmptyComponentOnlyMetadata()
    }

    static func buildEither(first: AnyComponentOnlyMetadata) -> AnyComponentOnlyMetadata {
        first
    }

    static func buildEither(second: AnyComponentOnlyMetadata) -> AnyComponentOnlyMetadata {
        second
    }

    static func buildArray(_ components: [AnyComponentOnlyMetadata]) -> AnyComponentOnlyMetadata {
        AnyComponentOnlyMetadataArray(components)
    }

    static func buildBlock(_ components: AnyComponentOnlyMetadata...) -> AnyComponentOnlyMetadata {
        AnyComponentOnlyMetadataArray(components)
    }
}

// MARK: Restricted WebService Metadata Block
public extension RestrictedMetadataBlockBuilder where Block: WebServiceMetadataBlock, Block.RestrictedContent: AnyWebServiceMetadata {
    static func buildExpression(_ expression: Block.RestrictedContent) -> AnyWebServiceMetadata {
        expression
    }

    static func buildExpression(_ expression: Block) -> AnyWebServiceMetadata {
        expression
    }

    static func buildOptional(_ component: AnyWebServiceMetadata?) -> AnyWebServiceMetadata {
        component ?? EmptyWebServiceMetadata()
    }

    static func buildEither(first: AnyWebServiceMetadata) -> AnyWebServiceMetadata {
        first
    }

    static func buildEither(second: AnyWebServiceMetadata) -> AnyWebServiceMetadata {
        second
    }

    static func buildArray(_ components: [AnyWebServiceMetadata]) -> AnyWebServiceMetadata {
        AnyWebServiceMetadataArray(components)
    }

    static func buildBlock(_ components: AnyWebServiceMetadata...) -> AnyWebServiceMetadata {
        AnyWebServiceMetadataArray(components)
    }
}

// MARK: Restricted Component Metadata Block
public extension RestrictedMetadataBlockBuilder where Block: ComponentMetadataBlock, Block.RestrictedContent: AnyComponentMetadata {
    static func buildExpression(_ expression: Block.RestrictedContent) -> AnyComponentMetadata {
        expression
    }

    static func buildExpression(_ expression: Block) -> AnyComponentMetadata {
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
        AnyComponentMetadataArray(components)
    }

    static func buildBlock(_ components: AnyComponentMetadata...) -> AnyComponentMetadata {
        AnyComponentMetadataArray(components)
    }
}

// MARK: Restricted Content Metadata Block
public extension RestrictedMetadataBlockBuilder where Block: ContentMetadataBlock, Block.RestrictedContent: AnyContentMetadata {
    static func buildExpression(_ expression: Block.RestrictedContent) -> AnyContentMetadata {
        expression
    }

    static func buildExpression(_ expression: Block) -> AnyContentMetadata {
        expression
    }

    static func buildOptional(_ component: AnyContentMetadata?) -> AnyContentMetadata {
        component ?? EmptyContentMetadata()
    }

    static func buildEither(first: AnyContentMetadata) -> AnyContentMetadata {
        first
    }

    static func buildEither(second: AnyContentMetadata) -> AnyContentMetadata {
        second
    }

    static func buildArray(_ components: [AnyContentMetadata]) -> AnyContentMetadata {
        AnyContentMetadataArray(components)
    }

    static func buildBlock(_ components: AnyContentMetadata...) -> AnyContentMetadata {
        AnyContentMetadataArray(components)
    }
}
