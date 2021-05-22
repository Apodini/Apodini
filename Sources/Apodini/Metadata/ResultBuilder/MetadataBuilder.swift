//
// Created by Andreas Bauer on 14.05.21.
//

// swiftlint:disable missing_docs

#if swift(>=5.4)
@resultBuilder
public enum MetadataBuilder {}
#else
@_functionBuilder
public enum MetadataBuilder {}
#endif

// MARK: Handler Metadata
public extension MetadataBuilder {
    static func buildExpression<Metadata: HandlerMetadataDefinition>(_ expression: Metadata) -> AnyHandlerMetadata {
        WrappedHandlerMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: HandlerMetadataGroup>(_ expression: Metadata) -> AnyHandlerMetadata {
        expression
    }

    static func buildExpression<Metadata: ComponentMetadataGroup>(_ expression: Metadata) -> AnyHandlerMetadata {
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
        AnyHandlerMetadataArrayWrapper(components)
    }

    static func buildBlock(_ components: AnyHandlerMetadata...) -> AnyHandlerMetadata {
        AnyHandlerMetadataArrayWrapper(components)
    }
}

// MARK: Component-Only Metadata
public extension MetadataBuilder {
    static func buildExpression<Metadata: ComponentOnlyMetadataDefinition>(_ expression: Metadata) -> AnyComponentOnlyMetadata {
        WrappedComponentOnlyMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: ComponentOnlyMetadataGroup>(_ expression: Metadata) -> AnyComponentOnlyMetadata {
        expression
    }

    static func buildExpression<Metadata: ComponentMetadataGroup>(_ expression: Metadata) -> AnyComponentOnlyMetadata {
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
        AnyComponentOnlyMetadataArrayWrapper(components)
    }

    static func buildBlock(_ components: AnyComponentOnlyMetadata...) -> AnyComponentOnlyMetadata {
        AnyComponentOnlyMetadataArrayWrapper(components)
    }
}

// MARK: WebService Metadata
public extension MetadataBuilder {
    static func buildExpression<Metadata: WebServiceMetadataDefinition>(_ expression: Metadata) -> AnyWebServiceMetadata {
        WrappedWebServiceMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: WebServiceMetadataGroup>(_ expression: Metadata) -> AnyWebServiceMetadata {
        expression
    }

    static func buildExpression<Metadata: ComponentMetadataGroup>(_ expression: Metadata) -> AnyWebServiceMetadata {
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
        AnyWebServiceMetadataArrayWrapper(components)
    }

    static func buildBlock(_ components: AnyWebServiceMetadata...) -> AnyWebServiceMetadata {
        AnyWebServiceMetadataArrayWrapper(components)
    }
}

// MARK: Content Metadata
public extension MetadataBuilder {
    static func buildExpression<Metadata: ContentMetadataDefinition>(_ expression: Metadata) -> AnyContentMetadata {
        WrappedContentMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: ContentMetadataGroup>(_ expression: Metadata) -> AnyContentMetadata {
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
