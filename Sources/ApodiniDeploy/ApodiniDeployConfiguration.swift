//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-02-07.
//

import Foundation
import Apodini

import ApodiniDeployBuildSupport
import ApodiniDeployRuntimeSupport


public struct ApodiniDeployConfiguration: Apodini.Configuration {
    struct StorageKey: Apodini.StorageKey {
        typealias Value = ApodiniDeployConfiguration
    }
    
    let runtimes: [DeploymentProviderRuntimeSupport.Type]
    let config: DeploymentConfig // TODO rename to options!?
    
    public init(runtimes: [DeploymentProviderRuntimeSupport.Type] = [], config: DeploymentConfig = .init()) {
        self.runtimes = runtimes
        self.config = config
    }
    
    public func configure(_ app: Application) {
        app.storage.set(StorageKey.self, to: self)
    }
}




// MARK: Pt 2


extension DeploymentGroup {
    /// Creates a single deployment group containing all handlers of type `H`.
    public static func allHandlers<H: Handler>(ofType _: H.Type, groupId: DeploymentGroup.ID? = nil) -> DeploymentGroup {
        DeploymentGroup(id: groupId, handlerTypes: [HandlerTypeIdentifier(H.self)], handlerIds: [])
    }
    
    /// Creates a deployment group containing the handlers with the specifiec identifiers
    public static func handlers(withIds handlerIds: Set<AnyHandlerIdentifier>, groupId: DeploymentGroup.ID? = nil) -> DeploymentGroup {
        DeploymentGroup(id: groupId, handlerTypes: [], handlerIds: handlerIds)
    }
}


struct DSLSpecifiedDeploymentGroupIdContextKey: OptionalContextKey {
    typealias Value = DeploymentGroup.ID
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        fatalError("Component cannot have multiple explicitly specified deployment groups. Cconflicting groups are '\(value)' and '\(nextValue())'")
    }
}



public struct DeploymentGroupModifier<Content: Component>: Modifier, SyntaxTreeVisitable {
    public let component: Content
    let groupId: DeploymentGroup.ID
    let options: [AnyDeploymentOption]
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DSLSpecifiedDeploymentGroupIdContextKey.self, value: groupId, scope: .environment)
        visitor.addContext(HandlerDeploymentOptionsSyntaxNodeContextKey.self, value: options, scope: .environment)
        component.accept(visitor)
    }
}



extension Group {
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



struct HandlerDeploymentOptionsSyntaxNodeContextKey: Apodini.ContextKey {
    typealias Value = [AnyDeploymentOption]
    
    static let defaultValue: Value = []
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}


public struct HandlerDeploymentOptionsModifier<H: Handler>: HandlerModifier, SyntaxTreeVisitable {
    public let component: H
    public let deploymentOptions: [AnyDeploymentOption]
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(HandlerDeploymentOptionsSyntaxNodeContextKey.self, value: deploymentOptions, scope: .environment)
        component.accept(visitor)
    }
}


extension Handler {
    public func deploymentOptions(_ options: AnyDeploymentOption...) -> HandlerDeploymentOptionsModifier<Self> {
        HandlerDeploymentOptionsModifier(component: self, deploymentOptions: options)
    }
}





public protocol HandlerWithDeploymentOptions: Handler {
    /// Type-level deployment options (ie options which apply to all instances of this type)
    static var deploymentOptions: [AnyDeploymentOption] { get }
}

extension HandlerWithDeploymentOptions {
    /// By default, `Handler`s dont't specify any type-level deployment options
    public static var deploymentOptions: [AnyDeploymentOption] {
        return []
    }
}
