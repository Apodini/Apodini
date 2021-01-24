//
//  Component.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
@_implementationOnly import Runtime
@_implementationOnly import AssociatedTypeRequirementsVisitor


/// A `Component` is the central building block of  Apodini. Each component handles a specific functionality of the Apodini web service.
///
/// A `Component`  consists of different other components as described by the `content` property.
public protocol Component {
    /// The type of `Component` this `Component` is made out of if the component is a composition of multiple subcomponents.
    associatedtype Content: Component
    
    /// Different other `Component`s that are composed to describe the functionality of the`Component`
    @ComponentBuilder
    var content: Content { get }
}


// MARK: Syntax Tree Visitor
extension Component {
    /// As the `SyntaxTreeVisitable` protocol is internal we are not able to make `Component` conform to the protocol.
    /// This implementation of `accept` provides a default implementation for `Component` that either forwards the visitor to a custom `accept` implementation provided by conforming to the `SyntaxTreeVisitable`
    /// or forwards the `SyntaxTreeVisitor` to the content of the `Component` in case the content is not of type `Never`.
    ///
    /// Each `Component` that needs to provide a custom `accept` implementation **must** conform to `SyntaxTreeVisitable` and **must** provide a custom `accept` implementation.
    /// We require that each Component that conforms to `SyntaxTreeVisitable` provides its own custom `accept` implementation to avoid an endless loop in the `accept` function.
    func accept(_ visitor: SyntaxTreeVisitor) {
        preconditionTypeIsStruct(Self.self, messagePrefix: "Component")
        if let visitable = self as? SyntaxTreeVisitable {
            visitable.accept(visitor)
        } else {
            HandlerVisitorHelperImpl(visitor: visitor)(self)
            if Self.Content.self != Never.self {
                visitor.enterContent {
                    content.accept(visitor)
                }
            }
        }
    }
}


private protocol HandlerVisitorHelperImplBase: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = HandlerVisitorHelperImplBase
    associatedtype Input = Handler
    associatedtype Output
    func callAsFunction<H: Handler>(_ value: H) -> Output
}

extension HandlerVisitorHelperImplBase {
    @inline(never)
    @_optimize(none)
    func _test() {
        _ = self(Text(""))
    }
}

private struct HandlerVisitorHelperImpl: HandlerVisitorHelperImplBase {
    let visitor: SyntaxTreeVisitor
    func callAsFunction<H: Handler>(_ value: H) {
        visitor.visit(handler: value)
    }
}
