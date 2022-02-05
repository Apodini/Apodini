//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import ApodiniDeployerBuildSupport
import OpenAPIKit

/// Identifier of the localhost Deployment Provider.
public let localhostDeploymentProviderId = DeploymentProviderID("apodini.ApodiniDeploymentProvider.Localhost")


public struct LocalhostLaunchInfo: Codable {
    public let port: Int
    
    public init(port: Int) {
        self.port = port
    }
}

public struct LocalhostDeployedSystem: AnyDeployedSystem {
    public var deploymentProviderId: DeploymentProviderID
    
    public var nodes: Set<DeployedSystemNode>
    
    public var openApiDocument: OpenAPI.Document
    
    public init(
        deploymentProviderId: DeploymentProviderID,
        nodes: Set<DeployedSystemNode>,
        openApiDocument: OpenAPI.Document
    ) {
        self.deploymentProviderId = deploymentProviderId
        self.nodes = nodes
        self.openApiDocument = openApiDocument
    }
}
