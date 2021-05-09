//
//  Handler.swift
//  
//
//  Created by Paul Schmiedmayer on 1/11/21.
//


/// A `Handler` is a `Component` which defines an endpoint and can handle requests.
public protocol Handler: Component {
    /// The type that is returned from the `handle()` method when the component handles a request. The return type of the `handle` method is encoded into the response send out to the client.
    associatedtype Response: ResponseTransformable
    
    /// A function that is called when a request reaches the `Handler`
    func handle() throws -> Response
}


extension Handler {
    /// By default, `Handler`s don't provide any further content
    public var content: some Component {
        EmptyComponent()
    }
}

