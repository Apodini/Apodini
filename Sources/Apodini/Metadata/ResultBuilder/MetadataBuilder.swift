//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//   

// swiftlint:disable missing_docs




//public protocol MetadataBuilderScope {
//    associatedtype MetadataTypee
//}




public enum MetadataBuilderScope_Handler {}
public enum MetadataBuilderScope_ComponentOnly {}
public enum MetadataBuilderScope_WebService {}



public protocol MetadataBuilderScope_AnyComponent {}
extension MetadataBuilderScope_Handler: MetadataBuilderScope_AnyComponent {}
extension MetadataBuilderScope_ComponentOnly: MetadataBuilderScope_AnyComponent {}


//public protocol MetadataBuilderScope_Handler: MetadataBuilderScope {
//    typealias MetadataTypee = AnyHandlerMetadata
//}
//public protocol MetadataBuilderScope_ComponentOnly: MetadataBuilderScope {
//    typealias MetadataTypee = AnyComponentOnlyMetadata
//}
//public protocol MetadataBuilderScope_WebService: MetadataBuilderScope {
//    typealias MetadataTypee = AnyWebServiceMetadata
//}



@resultBuilder
public enum MetadataBuilder<Scope> {}

// MARK: Handler Metadata
public extension MetadataBuilder where Scope == MetadataBuilderScope_Handler {
    static func buildExpression<Metadata: HandlerMetadataDefinition>(_ expression: Metadata) -> AnyHandlerMetadata {
        WrappedHandlerMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: HandlerMetadataBlock>(_ expression: Metadata) -> AnyHandlerMetadata {
        expression
    }

    static func buildExpression<Metadata: ComponentMetadataBlock>(_ expression: Metadata) -> AnyHandlerMetadata {
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

// MARK: Component-Only Metadata
public extension MetadataBuilder where Scope == MetadataBuilderScope_ComponentOnly {
//public extension MetadataBuilder where Scope.MetadataTypee: AnyComponentOnlyMetadata {
    static func buildExpression<Metadata: ComponentOnlyMetadataDefinition>(_ expression: Metadata) -> AnyComponentOnlyMetadata {
        WrappedComponentOnlyMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: ComponentOnlyMetadataBlock>(_ expression: Metadata) -> AnyComponentOnlyMetadata {
        expression
    }

    static func buildExpression<Metadata: ComponentMetadataBlock>(_ expression: Metadata) -> AnyComponentOnlyMetadata {
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

// MARK: WebService Metadata
public extension MetadataBuilder where Scope == MetadataBuilderScope_WebService {
    static func buildExpression<Metadata: WebServiceMetadataDefinition>(_ expression: Metadata) -> AnyWebServiceMetadata {
        WrappedWebServiceMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: WebServiceMetadataBlock>(_ expression: Metadata) -> AnyWebServiceMetadata {
        expression
    }

    static func buildExpression<Metadata: ComponentMetadataBlock>(_ expression: Metadata) -> AnyWebServiceMetadata {
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
