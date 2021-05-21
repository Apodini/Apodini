//
// Created by Andreas Bauer on 21.05.21.
//

import Foundation

public protocol MetadataDeclaration: AnyMetadata {
    associatedtype Key: OptionalContextKey

    var value: Key.Value { get }
    static var scope: Scope { get }
}

public extension MetadataDeclaration {
    static var scope: Scope {
        .current
    }
}

public extension MetadataDeclaration {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(Key.self, value: value, scope: Self.scope)
    }
}


public protocol HandlerMetadataDeclaration: MetadataDeclaration, AnyHandlerMetadata {}
// TODO document why ComponentOnlyMetadata should be used with care (Scope leaking)
public protocol ComponentOnlyMetadataDeclaration: MetadataDeclaration, AnyComponentOnlyMetadata {}
public protocol WebServiceMetadataDeclaration: MetadataDeclaration, AnyWebServiceMetadata {}

public protocol ComponentMetadataDeclaration: HandlerMetadataDeclaration, ComponentOnlyMetadataDeclaration,
    WebServiceMetadataDeclaration, AnyComponentMetadata {}

public protocol ContentMetadataDeclaration: MetadataDeclaration, AnyContentMetadata {}


public extension ComponentOnlyMetadataDeclaration {
    static var scope: Scope {
        .environment
    }
}

public extension ComponentMetadataDeclaration {
    static var scope: Scope {
        .environment
    }
}
