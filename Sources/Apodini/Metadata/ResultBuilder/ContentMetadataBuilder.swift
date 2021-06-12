//
// Created by Andreas Bauer on 06.06.21.
//

// swiftlint:disable missing_docs

// Having a separate MetadataBuilder for Content Metadata Blocks improves
// the error output of compiler errors for misplaced ComponentMetadataDefinitions

#if swift(>=5.4)
@resultBuilder
public enum ContentMetadataBuilder {}
#else
@_functionBuilder
public enum ContentMetadataBuilder {}
#endif

public extension ContentMetadataBuilder {
    static func buildExpression<Metadata: ContentMetadataDefinition>(_ expression: Metadata) -> AnyContentMetadata {
        WrappedContentMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: ContentMetadataBlock>(_ expression: Metadata) -> AnyContentMetadata {
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
        AnyContentMetadataArrayWrapper(components)
    }

    static func buildBlock(_ components: AnyContentMetadata...) -> AnyContentMetadata {
        AnyContentMetadataArrayWrapper(components)
    }
}
