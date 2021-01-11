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
    
    func accept(_ visitor: SyntaxTreeVisitor) {}
}


public struct EmptyHandler: Handler, SyntaxTreeVisitable {
    public typealias Response = Never
    func accept(_ visitor: SyntaxTreeVisitor) {}
}

extension Component where Content == Never {
    /// Default implementation which will simply crash
    public var content: Self.Content {
        fatalError("'\(Self.self).\(#function)' is not implemented because 'Self.Content' is set to '\(Self.Content.self)'")
    }
}

extension Handler where Response == Never {
    /// Default implementation which will simply crash
    public func handle() -> Self.Response {
        fatalError("'\(Self.self).\(#function)' is not implemented because 'Self.Response' is set to '\(Self.Response.self)'")
    }
}
