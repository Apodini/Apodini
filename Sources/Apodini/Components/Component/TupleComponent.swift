//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              


public struct TupleComponent<each C: Component>: Component, SyntaxTreeVisitable {
    public typealias Content = Never
    
    let component: (repeat each C)
    
    init(_ component: repeat each C) {
        self.component = (repeat each component)
    }
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.enterContent {
            repeat (each component).acceptInNewComponentContext(visitor)
        }
    }
}


private extension Component {
    func acceptInNewComponentContext(_ visitor: SyntaxTreeVisitor) {
        visitor.enterComponentContext {
            self.accept(visitor)
        }
    }
}
