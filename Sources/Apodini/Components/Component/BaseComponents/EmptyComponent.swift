//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
