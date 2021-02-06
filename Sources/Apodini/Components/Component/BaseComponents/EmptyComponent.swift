//
//  EmptyComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


/// A `Component` which does not contain any content
public struct EmptyComponent: Component, SyntaxTreeVisitable {
    /// `EmptyComponent` does not have any content.
    /// Accessing this property will result in a run-time crash.
    public var content: some Component {
        let imp = { () -> Self in
            fatalError("'\(Self.self)' does not implement the '\(#function)' property")
        }
        return imp()
    }
    
    public func accept(_ visitor: SyntaxTreeVisitor) {}
}


public struct EmptyHandler: Handler, SyntaxTreeVisitable {
    public typealias Response = Never
    public func accept(_ visitor: SyntaxTreeVisitor) {}
}
