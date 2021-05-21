//
// Created by Andreas Bauer on 21.05.21.
//

public protocol AnyMetadata {
    func accept(_ visitor: SyntaxTreeVisitor)
}

public protocol AnyHandlerMetadata: AnyMetadata {}
public protocol AnyComponentOnlyMetadata: AnyMetadata {}
public protocol AnyWebServiceMetadata: AnyMetadata {}

public protocol AnyComponentMetadata: AnyComponentOnlyMetadata, AnyHandlerMetadata, AnyWebServiceMetadata {}

public protocol AnyContentMetadata: AnyMetadata {}
