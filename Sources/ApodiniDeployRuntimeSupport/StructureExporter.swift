import Foundation
import Apodini
import ApodiniUtils
import ApodiniDeployBuildSupport

/// A protocol is used to define how the structure of the web service is retrieved and persisted.
/// This can be used in a custom subcommand of `export-ws-structure` to compute
/// the structure in a way that is suitable for each use case.
public protocol StructureExporter {
    /// The `URL` to which the structure is persisted to
    var fileUrl: URL { get }
    /// The id of the deployment provider that calle
    var providerID: DeploymentProviderID { get }
    
    var nodeIdProvider: (Set<CollectedEndpointInfo>) -> String { get }
    
//    init(fileUrl: URL, providerID: DeploymentProviderID)
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
    public var nodeIdProvider: (Set<CollectedEndpointInfo>) -> String {
        { _ in UUID().uuidString }
    }
    
    public func retrieveStructure(
        _ endpoints: Set<CollectedEndpointInfo>,
        config: DeploymentConfig,
        app: Application
    ) throws -> AnyDeployedSystem {
        try retrieveDefaultDeployedSystem(endpoints, config: config, app: app)
    }
    
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
            deploymentProviderId: self.providerID,
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

extension DeploymentGroup {
    // whether this group should contain the exported endpoint
    func matches(exportedEndpointInfo: CollectedEndpointInfo) -> Bool {
        handlerTypes.contains(exportedEndpointInfo.handlerType) || handlerIds.contains(exportedEndpointInfo.endpoint[AnyHandlerIdentifier.self])
    }
}


extension Sequence where Element == DeployedSystemNode {
    // check that, in the sequence of nodes, every handler appears in only one node
    public func assertHandlersLimitedToSingleNode() throws {
        var exportedHandlerIds = Set<AnyHandlerIdentifier>()
        // make sure a handler isn't listed in multiple nodes
        for node in self {
            for endpoint in node.exportedEndpoints {
                guard exportedHandlerIds.insert(endpoint.handlerId).inserted else {
                    throw ApodiniDeployRuntimeSupportError(
                        message: "Handler with id '\(endpoint.handlerId)' appears in multiple deployment groups, which is illegal."
                    )
                }
            }
        }
    }
    
    // check that the sequence of nodes contains all endpoints from the other set
    func assertContainsAllEndpointsIn(_ allEndpoints: Set<CollectedEndpointInfo>) throws {
        // make sure every handler appears in one node
        let exportedHandlerIds = Set(self.flatMap(\.exportedEndpoints).map(\.handlerId))
        let expectedHandlerIds = Set(allEndpoints.map { $0.endpoint[AnyHandlerIdentifier.self] })
        guard expectedHandlerIds == exportedHandlerIds else {
            assert(exportedHandlerIds.isSubset(of: expectedHandlerIds))
            // All handler ids which appear in one of the two sets, but not in both.
            // Since the set of exported handler ids is a subset of the set of all handler ids,
            // this difference is the set of all handlers which aren't exported by a node
            let diff = expectedHandlerIds.symmetricDifference(exportedHandlerIds)
            throw ApodiniDeployRuntimeSupportError(
                message: "Handler ids\(diff.map { "'\($0.rawValue)'" }.joined(separator: ", "))"
            )
        }
    }
}
