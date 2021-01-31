//
//  Handler.swift
//  
//
//  Created by Paul Schmiedmayer on 1/11/21.
//

import ApodiniDeployBuildSupport


/// A `Handler` is a `Component` which defines an endpoint and can handle requests.
public protocol Handler: Component {
    /// The type that is returned from the `handle()` method when the component handles a request. The return type of the `handle` method is encoded into the response send out to the client.
    associatedtype Response: ResponseTransformable
    
    /// A function that is called when a request reaches the `Handler`
    func handle() throws -> Response
    
    /// Type-level deployment options (ie options which apply to all instances of this type)
    static var deploymentOptions: HandlerDeploymentOptions { get }
    
    /// Instance-level deployment options (ie options which apply to just one instance of this type)
    var deploymentOptions: HandlerDeploymentOptions { get }
}


extension Handler {
    /// By default, `Handler`s dont't provide any further content
    public var content: some Component {
        EmptyComponent()
    }
    
    /// By default, `Handler`s dont't specify any type-level deployment options
    public static var deploymentOptions: HandlerDeploymentOptions {
        HandlerDeploymentOptions()
    }
    
    /// By default, `Handler`s dont't specify any instance-level deployment options
    public var deploymentOptions: HandlerDeploymentOptions {
        HandlerDeploymentOptions()
    }
}


struct HandlerDeploymentOptionsSyntaxNodeContextKey: ContextKey {
    typealias Value = HandlerDeploymentOptions
    
    static let defaultValue = HandlerDeploymentOptions()
    
    static func reduce(value: inout HandlerDeploymentOptions, nextValue: () -> HandlerDeploymentOptions) {
        // Latter-defined options take precedence over previously defined options.
        // Note that this is different from simply appending and then reversing the array when reading options,
        // since this preserves the order within each set of options
        value = value.merging(with: nextValue(), newOptionsPrecedence: .higher)
    }
}


public struct HandlerDeploymentOptionsModifier<H: Handler>: HandlerModifier, SyntaxTreeVisitable {
    public let component: H
    public let deploymentOptions: HandlerDeploymentOptions
    
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(HandlerDeploymentOptionsSyntaxNodeContextKey.self, value: deploymentOptions, scope: .environment)
        component.accept(visitor)
    }
}


extension Handler {
    public func deploymentOptions(_ collectedOptions: CollectedHandlerConfigOption...) -> HandlerDeploymentOptionsModifier<Self> {
        HandlerDeploymentOptionsModifier(component: self, deploymentOptions: HandlerDeploymentOptions(collectedOptions))
    }
}
