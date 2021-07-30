//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniUtils
import ApodiniDeployBuildSupport
import ArgumentParser

/// A protocol is used to define how the structure of the web service is retrieved and persisted.
/// This defines a custom subcommand of `export-ws-structure` and allows to compute
/// the structure accounting for the needs of the deployment provider.
public protocol StructureExporter: ParsableCommand {
    /// The filePath to which the structure is persisted to
    var filePath: String { get }
    /// The id of the deployment provider that calle
    var identifier: String { get }
    /// Specifies how the id of the deployment node should be computed
    var nodeIdProvider: (Set<CollectedEndpointInfo>) -> String { get }
    
    /// Defines how the structure is retrieved.
    /// This is called from `ApodiniDeployInterfaceExporter` when the web service is started.
    /// The service automatically quits after `retrieveStructure` is called.
    /// - Parameter endpoints: A set of `CollectedEndpointInfo` over all the endpoints in the service
    /// - Parameter config: The `DeploymentConfig` containing deployment groups.
    /// - Parameter app: An instance of the Apodini `Application`.
    func retrieveStructure(
        _ endpoints: Set<CollectedEndpointInfo>,
        config: DeploymentConfig,
        app: Application
    ) throws -> AnyDeployedSystem
}

// MARK: - Default implementations of `StructureExporter`
extension StructureExporter {
    /// Specifies how the id of the deployment node should be computed
    public var nodeIdProvider: (Set<CollectedEndpointInfo>) -> String {
        { _ in UUID().uuidString }
    }
    
    /// Defines how the structure is retrieved.
    /// This is called from `ApodiniDeployInterfaceExporter` when the web service is started.
    /// The service automatically quits after `retrieveStructure` is called.
    public func retrieveStructure(
        _ endpoints: Set<CollectedEndpointInfo>,
        config: DeploymentConfig,
        app: Application
    ) throws -> AnyDeployedSystem {
        try retrieveDefaultDeployedSystem(endpoints, config: config, app: app)
    }
    
    /// Computes the default deployed system where all endpoints are matched to deployment groups if possible.
    public func retrieveDefaultDeployedSystem(
        _ endpoints: Set<CollectedEndpointInfo>,
        config: DeploymentConfig,
        app: Application
    ) throws -> DeployedSystem {
        // a mapping from all user-defined deployment groups, to the set of
        var endpointsByDeploymentGroup = [DeploymentGroup: Set<CollectedEndpointInfo>](
            uniqueKeysWithValues: config.deploymentGroups.map { ($0, []) }
        )
        // all endpoints which didn't match any of the user-defined deployment groups
        var remainingEndpoints: Set<CollectedEndpointInfo> = []
        
        for endpoint in endpoints {
            // for each exported endpoint (ie, handler in the DSL), find a matching node, based on the deployment group
            // all groups in which the endpoint would be allowed to be, based on the deployment options
            let matchingGroups = endpointsByDeploymentGroup.keys.filter { $0.matches(exportedEndpointInfo: endpoint) }
            switch matchingGroups.count {
            case 0:
                // the endpoint didn't match any deployment groups
                remainingEndpoints.insert(endpoint)
            case 1:
                // the endpoint matched exactly one group, so we'll put it in there
                endpointsByDeploymentGroup[matchingGroups[0]]!.insert(endpoint) // swiftlint:disable:this force_unwrapping
            default:
                // the endpoint matched multiple deployment groups, which results in ambiguity, and therefore is forbidden
                throw ApodiniDeployRuntimeSupportError(
                    message: "Endpoint with handlerId '\(endpoint.endpoint[AnyHandlerIdentifier.self].rawValue)' matches multiple deployment groups: \(matchingGroups.map({ "'\($0.id)'" }).joined(separator: ", "))"
                )
            }
        }
        
        // The nodes w/in the deployed system
        var nodes: Set<DeployedSystemNode> = []
        
        // one node per deployment group
        nodes += try endpointsByDeploymentGroup.map { deploymentGroup, endpoints in
            try DeployedSystemNode(
                id: deploymentGroup.id,
                exportedEndpoints: endpoints.convert(),
                userInfo: nil,
                userInfoType: Null.self
            )
        }
        
        switch config.defaultGrouping {
        case .separateNodes:
            nodes += try remainingEndpoints.map { endpoint in
                try DeployedSystemNode(
                    id: nodeIdProvider([endpoint]),
                    exportedEndpoints: [endpoint.convert()],
                    userInfo: nil,
                    userInfoType: Null.self
                )
            }
        case .singleNode:
            nodes.insert(try DeployedSystemNode(
                id: nodeIdProvider(remainingEndpoints),
                exportedEndpoints: remainingEndpoints.convert(),
                userInfo: nil,
                userInfoType: Null.self
            ))
        }
        
        try nodes.assertHandlersLimitedToSingleNode()
        try nodes.assertContainsAllEndpointsIn(endpoints)
        
        return try DeployedSystem(
            deploymentProviderId: DeploymentProviderID(rawValue: self.identifier),
            nodes: nodes,
            userInfo: nil,
            userInfoType: Null.self
        )
    }
}

extension CollectedEndpointInfo {
    func convert() -> ExportedEndpoint {
        ExportedEndpoint(
            handlerType: self.handlerType,
            handlerId: endpoint[AnyHandlerIdentifier.self],
            deploymentOptions: self.deploymentOptions,
            userInfo: [:]
        )
    }
}

extension Sequence where Element == CollectedEndpointInfo {
    func convert() -> Set<ExportedEndpoint> {
        Set(
            map { $0.convert() }
        )
    }
}
