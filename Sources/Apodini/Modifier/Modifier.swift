//
//  Modifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


/// A modifier which can be invoked on a `Component`
public protocol Modifier: Component {
    associatedtype ModifiedComponent: Component
    typealias Content = Never
    
    var component: ModifiedComponent { get }
}


/// A modifier which can be invoked on a `Handler` or a `Component`
public protocol HandlerModifier: Modifier, Handler where ModifiedComponent: Handler {
    associatedtype Response = ModifiedComponent.Response
    var component: ModifiedComponent { get }
}


public extension HandlerModifier {
    typealias EndpointIdentifier = ModifiedComponent.EndpointIdentifier
    
    var content: some Component { EmptyComponent() }
    
    func handle() -> Response {
        fatalError("A Modifier's handle method should never be called!")
    }
    
    var __endpointId: EndpointIdentifier { component.__endpointId }
}
