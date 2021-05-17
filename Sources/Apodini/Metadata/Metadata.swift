//
// Created by Andreas Bauer on 16.05.21.
//

// TODO conformance with SynteaxTreeVisitable => make that transparent, such that the option is added automatically to the Context
public protocol AnyMetadata: SyntaxTreeVisitable {}

public protocol MetadataDeclaration: AnyMetadata { // "Metadata" name is already taken by the associatedtype in e.g. Component
    associatedtype Key: OptionalContextKey

    var value: Key.Value { get }
    static var scope: Scope { get }
}

// MARK: SyntaxTreeVisitor
public extension MetadataDeclaration {
    static var scope: Scope {
        .current
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        if let group = self as? MetadataGroup {
            group.acceptVisitor(visitor)
        } else {
            visitor.addContext(Key.self, value: value, scope: Self.scope)
        }
    }
}

extension Never: OptionalContextKey {} // TODO move the extension


public protocol WebServiceMetadata: MetadataDeclaration {}

public protocol HandlerMetadata: MetadataDeclaration {}

public protocol ComponentOnlyMetadata: MetadataDeclaration {} // TODO document why ComponentOnlyMetadata isn't that useful (Scope)
public extension ComponentOnlyMetadata {
    static var scope: Scope {
        .environment
    }
}

public protocol ComponentMetadata: ComponentOnlyMetadata, HandlerMetadata, WebServiceMetadata {}
public extension ComponentMetadata {
    static var scope: Scope {
        .environment
    }
}

public protocol ContentMetadata: MetadataDeclaration {}
