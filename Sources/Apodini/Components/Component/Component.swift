//
//  Component.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import ApodiniUtils
@_implementationOnly import AssociatedTypeRequirementsVisitor


/// A `Component` is the central building block of  Apodini. Each component handles a specific functionality of the Apodini web service.
///
/// A `Component`  consists of different other components as described by the `content` property.
public protocol Component: ComponentOnlyMetadataNamespace, ComponentMetadataNamespace {
    /// The type of `Component` this `Component` is made out of if the component is a composition of multiple subcomponents.
    associatedtype Content: Component

    associatedtype Metadata = AnyComponentOnlyMetadata
    
    /// Different other `Component`s that are composed to describe the functionality of the`Component`
    @ComponentBuilder
    var content: Content { get }

    @MetadataBuilder
    var metadata: Metadata { get }
}

// MARK: Metadata DSL
public extension Component {
    /// Components have an empty `AnyComponentOnlyMetadata` by default.
    var metadata: AnyComponentOnlyMetadata {
        Empty()
    }
}

// MARK: Syntax Tree Visitor
extension Component {
    /// As the `SyntaxTreeVisitable` protocol is internal we are not able to make `Component` conform to the protocol.
    /// This implementation of `accept` provides a default implementation for `Component` that either forwards the visitor to a custom `accept` implementation provided by conforming to the `SyntaxTreeVisitable`
    /// or forwards the `SyntaxTreeVisitor` to the content of the `Component` in case the content is not of type `Never`.
    ///
    /// Each `Component` that needs to provide a custom `accept` implementation **must** conform to `SyntaxTreeVisitable` and **must** provide a custom `accept` implementation.
    /// We require that each Component that conforms to `SyntaxTreeVisitable` provides its own custom `accept` implementation to avoid an endless loop in the `accept` function.
    public func accept(_ visitor: SyntaxTreeVisitor) {
        preconditionTypeIsStruct(Self.self, messagePrefix: "Component")

        if let visitable = self as? SyntaxTreeVisitable {
            // This cases covers any Components conforming to SyntaxTreeVisitable.
            // Most commonly this are Modifiers, but also Components like `Group`
            // or special purpose Components like `TupleComponent`

            // As stated above, this might be a Modifier and the Metadata of Modifiers can't be accessed.
            // So we only start parsing the metadata if in fact we know that it isn't a Modifier.
            if StandardModifierVisitor()(self) != true {
                (metadata as! AnyMetadata).accept(visitor)
            }

            visitable.accept(visitor)
        } else {
            let visited = HandlerVisitorHelperImpl(visitor: visitor)(self) != nil

            if !visited {
                // Covering components which are not Handlers and don't conform to `SyntaxTreeVisitable`.
                // Such Components are typically constructed by users.
                // Executed before we enter the content below.
                (metadata as! AnyMetadata).accept(visitor)
            }

            if Self.Content.self != Never.self {
                visitor.enterContent {
                    visitor.enterComponentContext {
                        content.accept(visitor)
                    }
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
    fileprivate func _test() {
        _ = self(Text(""))
    }
}

private struct HandlerVisitorHelperImpl: HandlerVisitorHelperImplBase {
    let visitor: SyntaxTreeVisitor
    func callAsFunction<H: Handler>(_ value: H) {
        visitor.visit(handler: value)
    }
}


private protocol ModifierVisitor: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = ModifierVisitor
    associatedtype Input = Modifier
    associatedtype Output

    func callAsFunction<M: Modifier>(_ value: M) -> Output
}

private struct TestModifier: Modifier {
    var component = Text("")
}

extension ModifierVisitor {
    @inline(never)
    @_optimize(none)
    fileprivate func _test() {
        _ = self(TestModifier())
    }
}

private struct StandardModifierVisitor: ModifierVisitor {
    func callAsFunction<M: Modifier>(_ value: M) -> Bool {
        true
    }
}
