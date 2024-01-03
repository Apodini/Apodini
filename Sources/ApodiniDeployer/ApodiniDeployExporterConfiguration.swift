//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini

import ApodiniDeployerBuildSupport
import ApodiniDeployerRuntimeSupport

extension ApodiniDeployer {
    struct ExporterConfiguration {
        let runtimes: [any DeploymentProviderRuntime.Type]
        let config: DeploymentConfig
        
        init(
            runtimes: [any DeploymentProviderRuntime.Type] = [],
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
    
    static func reduce(value: inout Value, nextValue: Value) {
        fatalError("Component cannot have multiple explicitly specified deployment groups. Conflicting groups are '\(value)' and '\(nextValue)'")
    }
}


public struct DeploymentGroupModifier<Content: Component>: Modifier {
    public let component: Content
    let groupId: DeploymentGroup.ID

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DSLSpecifiedDeploymentGroupIdContextKey.self, value: groupId, scope: .environment)
    }
}


extension Group {
    /// Form a deployment group based on the handlers contained in this `Group`
    public func formDeploymentGroup(
        withId groupId: DeploymentGroup.ID? = nil
    ) -> DeploymentGroupModifier<Self> {
        DeploymentGroupModifier(
            component: self,
            groupId: groupId ?? DeploymentGroup.generateGroupId()
        )
    }
}
