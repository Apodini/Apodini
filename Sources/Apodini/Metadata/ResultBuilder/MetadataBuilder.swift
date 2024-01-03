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
    static func buildExpression<Metadata: HandlerMetadataDefinition>(_ expression: Metadata) -> any AnyHandlerMetadata {
        WrappedHandlerMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: HandlerMetadataBlock>(_ expression: Metadata) -> any AnyHandlerMetadata {
        expression
    }

    static func buildExpression<Metadata: ComponentMetadataBlock>(_ expression: Metadata) -> any AnyHandlerMetadata {
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

// MARK: Component-Only Metadata
public extension MetadataBuilder where Scope == MetadataBuilderScope_ComponentOnly {
//public extension MetadataBuilder where Scope.MetadataTypee: AnyComponentOnlyMetadata {
    static func buildExpression<Metadata: ComponentOnlyMetadataDefinition>(_ expression: Metadata) -> any AnyComponentOnlyMetadata {
        WrappedComponentOnlyMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: ComponentOnlyMetadataBlock>(_ expression: Metadata) -> any AnyComponentOnlyMetadata {
        expression
    }

    static func buildExpression<Metadata: ComponentMetadataBlock>(_ expression: Metadata) -> any AnyComponentOnlyMetadata {
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

// MARK: WebService Metadata
public extension MetadataBuilder where Scope == MetadataBuilderScope_WebService {
    static func buildExpression<Metadata: WebServiceMetadataDefinition>(_ expression: Metadata) -> any AnyWebServiceMetadata {
        WrappedWebServiceMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: WebServiceMetadataBlock>(_ expression: Metadata) -> any AnyWebServiceMetadata {
        expression
    }

    static func buildExpression<Metadata: ComponentMetadataBlock>(_ expression: Metadata) -> any AnyWebServiceMetadata {
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
