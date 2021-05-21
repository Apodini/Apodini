//
// Created by Andreas Bauer on 21.05.21.
//

import Foundation

public protocol MetadataDefinition: AnyMetadata {
    associatedtype Key: OptionalContextKey

    var value: Key.Value { get }
    static var scope: Scope { get }
}

public extension MetadataDefinition {
    static var scope: Scope {
        .current
    }
}

public extension MetadataDefinition {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(Key.self, value: value, scope: Self.scope)
    }
}


public protocol HandlerMetadataDefinition: MetadataDefinition, AnyHandlerMetadata {}
// TODO document why ComponentOnlyMetadata should be used with care (Scope leaking)
public protocol ComponentOnlyMetadataDefinition: MetadataDefinition, AnyComponentOnlyMetadata {}
public protocol WebServiceMetadataDefinition: MetadataDefinition, AnyWebServiceMetadata {}

public protocol ComponentMetadataDefinition: HandlerMetadataDefinition, ComponentOnlyMetadataDefinition,
    WebServiceMetadataDefinition, AnyComponentMetadata {}

public protocol ContentMetadataDefinition: MetadataDefinition, AnyContentMetadata {}


public extension ComponentOnlyMetadataDefinition {
    static var scope: Scope {
        .environment
    }
}

public extension ComponentMetadataDefinition {
    static var scope: Scope {
        .environment
    }
}
