//
//  ApodiniDeployExporterConfiguration.swift
//  
//
//  Created by Lukas Kollmer on 2021-02-07.
//

import Foundation
import Apodini

import ApodiniDeployBuildSupport
import ApodiniDeployRuntimeSupport

extension ApodiniDeploy {
    struct ExporterConfiguration {
        let runtimes: [DeploymentProviderRuntime.Type]
        let config: DeploymentConfig
        
        init(
            runtimes: [DeploymentProviderRuntime.Type] = [],
            config: DeploymentConfig = .init()
        ) {
            self.runtimes = runtimes
            self.config = config
        }
    }
}

extension DeploymentGroup {
    /// Creates a single deployment group containing all handlers of type `H`.
    public static func allHandlers<H: Handler>(ofType _: H.Type, groupId: DeploymentGroup.ID? = nil) -> DeploymentGroup {
        DeploymentGroup(id: groupId, handlerTypes: [HandlerTypeIdentifier(H.self)], handlerIds: [])
    }
    
    /// Creates a deployment group containing the handlers with the specific identifiers
    public static func handlers(withIds handlerIds: Set<AnyHandlerIdentifier>, groupId: DeploymentGroup.ID? = nil) -> DeploymentGroup {
        DeploymentGroup(id: groupId, handlerTypes: [], handlerIds: handlerIds)
    }
}


struct DSLSpecifiedDeploymentGroupIdContextKey: OptionalContextKey {
    typealias Value = DeploymentGroup.ID
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        fatalError("Component cannot have multiple explicitly specified deployment groups. Conflicting groups are '\(value)' and '\(nextValue())'")
    }
}


public struct DeploymentGroupModifier<Content: Component>: Modifier, SyntaxTreeVisitable {
    public let component: Content
    let groupId: DeploymentGroup.ID
    let options: [AnyDeploymentOption]
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DSLSpecifiedDeploymentGroupIdContextKey.self, value: groupId, scope: .environment)
        visitor.addContext(HandlerDeploymentOptionsContextKey.self, value: options, scope: .environment)
        component.accept(visitor)
    }
}


extension Group {
    /// Form a deployment group based on the handlers contained in this `Group`
    public func formDeploymentGroup(
        withId groupId: DeploymentGroup.ID? = nil,
        options: [AnyDeploymentOption] = []
    ) -> DeploymentGroupModifier<Self> {
        DeploymentGroupModifier(
            component: self,
            groupId: groupId ?? DeploymentGroup.generateGroupId(),
            options: options
        )
    }
}


struct HandlerDeploymentOptionsContextKey: Apodini.ContextKey {
    typealias Value = [AnyDeploymentOption]
    
    static let defaultValue: Value = []
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}


public struct DeploymentOptionsModifier<C: Component>: Modifier, SyntaxTreeVisitable {
    public let component: C
    public let deploymentOptions: [AnyDeploymentOption]
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(HandlerDeploymentOptionsContextKey.self, value: deploymentOptions, scope: .environment)
        component.accept(visitor)
    }
}

extension DeploymentOptionsModifier: Handler, HandlerModifier, HandlerMetadataNamespace where Self.ModifiedComponent: Handler {
    public typealias Response = ModifiedComponent.Response
}


extension Component {
    /// Attach a set of deployment options to the handler
    public func deploymentOptions(_ options: AnyDeploymentOption...) -> DeploymentOptionsModifier<Self> {
        DeploymentOptionsModifier(component: self, deploymentOptions: options)
    }
}


/// A `Handler` which specifies deployment options
public protocol HandlerWithDeploymentOptions: Handler {
    /// Type-level deployment options (ie options which apply to all instances of this type)
    static var deploymentOptions: [AnyDeploymentOption] { get }
}

extension HandlerWithDeploymentOptions {
    /// By default, `Handler`s don't specify any type-level deployment options
    public static var deploymentOptions: [AnyDeploymentOption] {
        []
    }
}
