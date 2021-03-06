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
    /// `HandlerModifier`s don't provide any further content
    /// - Note: this property should not be implenented in a modifier type
    var content: some Component { EmptyComponent() }
    
    /// `HandlerModifier`s don't implement the `handle` function
    /// - Note: this function should not be implenented in a modifier type
    func handle() -> Response {
        fatalError("A Modifier's handle method should never be called!")
    }
}
