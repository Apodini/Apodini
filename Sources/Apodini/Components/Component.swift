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


/// A `Handler` is a `Component` which defines an endpoint and can handle requests.
public protocol Handler: Component {
    /// The type that is returned from the `handle()` method when the component handles a request. The return type of the `handle` method is encoded into the response send out to the client.
    associatedtype Response: Encodable
    
    /// A function that is called when a request reaches the `Handler`
    func handle() -> Response
}


extension Handler {
    /// By default, `Handler`s dont't provide any further content
    public var content: some Component {
        EmptyComponent()
    }
}


/// A `Handler` which can be uniquely identified
public protocol IdentifiableHandler: Handler {
    /// The type of this handler's identifier
    associatedtype HandlerIdentifier: AnyHandlerIdentifier
    
    /// This handler's identifier
    var handlerId: HandlerIdentifier { get }
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
        assertTypeIsStruct(Self.self, messagePrefix: "Component")
        if let visitable = self as? SyntaxTreeVisitable {
            visitable.accept(visitor)
        } else {
            if Self.Content.self != Never.self {
                content.accept(visitor)
            }
            HandlerVisitorHelperImpl(visitor: visitor)(self)
        }
    }
}


/// - parameter T: The type for which to assert that it is a struct
/// - parameter messagePrefix: An optional string which will be prefixed to the "T must be a struct" message
internal func assertTypeIsStruct<T>(_: T.Type, messagePrefix: String? = nil) {
    guard let typeInfo = try? Runtime.typeInfo(of: T.self) else {
        fatalError("Unable to get type info for type '\(T.self)'")
    }
    precondition(typeInfo.kind == .struct, "\(messagePrefix.map { $0 + " " } ?? "")'\(typeInfo.name)' must be a struct")
}


private protocol HandlerVisitorHelperImplBase: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = HandlerVisitorHelperImplBase
    associatedtype Input = Handler
    associatedtype Output
    func callAsFunction<H: Handler>(_ value: H) -> Output
}

private struct HandlerVisitorHelperImpl: HandlerVisitorHelperImplBase {
    let visitor: SyntaxTreeVisitor
    func callAsFunction<H: Handler>(_ value: H) {
        visitor.visit(handler: value)
    }
}
