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
    
    /// The type of this handler's identifier
    associatedtype EndpointIdentifier: AnyEndpointIdentifier

    /// A function that is called when a request reaches the `Handler`
    func handle() -> Response
    
    // underscored as to avoid clashes w/ potential parameters, or other custom properties of the conforming type
    var __endpointId: EndpointIdentifier { get }
}


/// Default implementation for components which don't specify an identifier
extension Handler where EndpointIdentifier == AnyEndpointIdentifier {
    public var __endpointId: EndpointIdentifier { .init(Self.self) }
}


extension Handler {
    public var content: some Component { EmptyComponent() }
}


extension Component {
    func visit(_ visitor: SyntaxTreeVisitor) {
        LKAssertTypeIsStruct(Self.self)
        if let visitable = self as? Visitable {
            visitable.visit(visitor)
        } else {
            if Content.self != Never.self {
                content.visit(visitor)
            }
            HandlerVisitorHelperImpl(visitor: visitor)(self)
        }
    }
}


private func LKAssertTypeIsStruct<T>(_: T.Type) {
    guard let TI = try? typeInfo(of: T.self) else {
        fatalError("Unable to get type info for type '\(T.self)'")
    }
    precondition(TI.kind == .struct, "Node '\(TI.name)' must be a struct")
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
        visitor.register(component: value)
    }
}
