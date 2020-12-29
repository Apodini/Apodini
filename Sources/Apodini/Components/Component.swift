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
    public var content: some Component { EmptyComponent() }
}


/// A `Handler` which can be uniquely identified
public protocol IdentifiableHandler: Handler {
    /// The type of this handler's identifier
    associatedtype EndpointIdentifier: AnyEndpointIdentifier
    
    /// This handler's identifier
    var endpointId: EndpointIdentifier { get }
}


extension Component {
    func visit(_ visitor: SyntaxTreeVisitor) {
        LKAssertTypeIsStruct(Self.self)
        if let visitable = self as? Visitable {
            visitable.visit(visitor)
        } else {
            if Content.self != Never.self {
                visitor.enterCollection()
                content.visit(visitor)
                visitor.exitCollection()
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
        visitor.register(handler: value)
    }
}
