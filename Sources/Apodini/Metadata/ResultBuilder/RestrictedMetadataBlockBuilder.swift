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
    static func buildExpression(_ expression: Block.RestrictedContent) -> any AnyHandlerMetadata {
        expression
    }

    static func buildExpression(_ expression: Block) -> any AnyHandlerMetadata {
        expression
    }

    static func buildOptional(_ component: (any AnyHandlerMetadata)?) -> any AnyHandlerMetadata {
        component ?? EmptyHandlerMetadata()
    }

    static func buildEither(first: any AnyHandlerMetadata) -> any AnyHandlerMetadata {
        first
    }

    static func buildEither(second: any AnyHandlerMetadata) -> any AnyHandlerMetadata {
        second
    }

    static func buildArray(_ components: [any AnyHandlerMetadata]) -> any AnyHandlerMetadata {
        AnyHandlerMetadataArray(components)
    }

    static func buildBlock(_ components: any AnyHandlerMetadata...) -> any AnyHandlerMetadata {
        AnyHandlerMetadataArray(components)
    }
}

// MARK: Restricted Component-Only Metadata Block
public extension RestrictedMetadataBlockBuilder where Block: ComponentOnlyMetadataBlock, Block.RestrictedContent: AnyComponentOnlyMetadata {
    static func buildExpression(_ expression: Block.RestrictedContent) -> any AnyComponentOnlyMetadata {
        expression
    }

    static func buildExpression(_ expression: Block) -> any AnyComponentOnlyMetadata {
        expression
    }

    static func buildOptional(_ component: (any AnyComponentOnlyMetadata)?) -> any AnyComponentOnlyMetadata {
        component ?? EmptyComponentOnlyMetadata()
    }

    static func buildEither(first: any AnyComponentOnlyMetadata) -> any AnyComponentOnlyMetadata {
        first
    }

    static func buildEither(second: any AnyComponentOnlyMetadata) -> any AnyComponentOnlyMetadata {
        second
    }

    static func buildArray(_ components: [any AnyComponentOnlyMetadata]) -> any AnyComponentOnlyMetadata {
        AnyComponentOnlyMetadataArray(components)
    }

    static func buildBlock(_ components: any AnyComponentOnlyMetadata...) -> any AnyComponentOnlyMetadata {
        AnyComponentOnlyMetadataArray(components)
    }
}

// MARK: Restricted WebService Metadata Block
public extension RestrictedMetadataBlockBuilder where Block: WebServiceMetadataBlock, Block.RestrictedContent: AnyWebServiceMetadata {
    static func buildExpression(_ expression: Block.RestrictedContent) -> any AnyWebServiceMetadata {
        expression
    }

    static func buildExpression(_ expression: Block) -> any AnyWebServiceMetadata {
        expression
    }

    static func buildOptional(_ component: (any AnyWebServiceMetadata)?) -> any AnyWebServiceMetadata {
        component ?? EmptyWebServiceMetadata()
    }

    static func buildEither(first: any AnyWebServiceMetadata) -> any AnyWebServiceMetadata {
        first
    }

    static func buildEither(second: any AnyWebServiceMetadata) -> any AnyWebServiceMetadata {
        second
    }

    static func buildArray(_ components: [any AnyWebServiceMetadata]) -> any AnyWebServiceMetadata {
        AnyWebServiceMetadataArray(components)
    }

    static func buildBlock(_ components: any AnyWebServiceMetadata...) -> any AnyWebServiceMetadata {
        AnyWebServiceMetadataArray(components)
    }
}

// MARK: Restricted Component Metadata Block
public extension RestrictedMetadataBlockBuilder where Block: ComponentMetadataBlock, Block.RestrictedContent: AnyComponentMetadata {
    static func buildExpression(_ expression: Block.RestrictedContent) -> any AnyComponentMetadata {
        expression
    }

    static func buildExpression(_ expression: Block) -> any AnyComponentMetadata {
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
