//
// Created by Andreas Bauer on 21.05.21.
//

// swiftlint:disable missing_docs

#if swift(>=5.4)
@resultBuilder
public enum ComponentMetadataBuilder {}
#else
@_functionBuilder
public enum ComponentMetadataBuilder {}
#endif

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
