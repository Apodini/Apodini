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
    
//    /// Type-level deployment options (ie options which apply to all instances of this type)
//    static var deploymentOptions: [AnyDeploymentOption] { get } // TODO replace these arrays w/ `DeploymentOptions`?
    
//    /// Instance-level deployment options (ie options which apply to just one instance of this type)
//    var deploymentOptions: [AnyDeploymentOption] { get }
}


extension Handler {
    /// By default, `Handler`s don't provide any further content
    public var content: some Component {
        EmptyComponent()
    }
    
//    /// By default, `Handler`s dont't specify any type-level deployment options
//    public static var deploymentOptions: [AnyDeploymentOption] {
//        []
//    }
    
//    /// By default, `Handler`s dont't specify any instance-level deployment options
//    public var deploymentOptions: [AnyDeploymentOption] {
//        []
//    }
}
