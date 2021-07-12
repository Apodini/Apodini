//
//  DeploymentProvider.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-31.
//


import Foundation
import Logging
import Apodini
import ApodiniUtils


public struct DeploymentProviderID: RawRepresentable, Hashable, Equatable, Codable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct DeploymentMemoryStorage: MemoryStorage {
    public static var current = DeploymentMemoryStorage()
    
    private var object: WebServiceStructure?
    
    public mutating func store(_ object: WebServiceStructure) {
        self.object = object
    }

    public func retrieve() -> WebServiceStructure? {
        object
    }
}


/// The target on which a deployment provider operates.
/// Used by the default operations implemented by ApodiniDeploy.
public enum DeploymentProviderTarget {
    /// An SPM target in a package at the specified location
    case spmTarget(packageUrl: URL, targetName: String)
    
    /// An already-built executable
    case executable(URL)
}


/// A deployment provider, i.e. a type which can manage and facilitate the process of deploying a web service to some target platform
public protocol DeploymentProvider {
    /// This deployment provider's identifier. Must be unique. Use reverse DNS or something like that
    static var identifier: DeploymentProviderID { get }
    
    /// The target on which this deployment provider operates.
    var target: DeploymentProviderTarget { get }
    
    /// Whether ApodiniDeploy's default implementations should launch child processes in the current process group.
    /// - Note: This should be `true` in most circumstances. Only specify this as `false` if your specific deployment
    /// provider actually needs this behaviour.
    var launchChildrenInCurrentProcessGroup: Bool { get }
}


public extension DeploymentProvider {
    var identifier: DeploymentProviderID { // swiftlint:disable:this missing_docs
        Self.identifier
    }
    
    var launchChildrenInCurrentProcessGroup: Bool { true } // swiftlint:disable:this missing_docs
}


public struct ApodiniDeployBuildSupportError: Swift.Error {
    let message: String
    
    public init(message: String) {
        self.message = message
    }
}


extension DeploymentProvider {
    /// Retrieves the web service structure that has been saved by the same process.
    public func retrieveWebServiceStructure() throws -> WebServiceStructure {
        guard let wsStructure = DeploymentMemoryStorage.current.retrieve() else {
            throw ApodiniDeployBuildSupportError(message: "Failed to retrieve DeploymentStorage.")
        }
        return wsStructure
    }
    
    private static func getSwiftBinUrl() throws -> URL {
        if let swiftBin = Task.findExecutable(named: "swift") {
            return swiftBin
        } else {
            throw ApodiniDeployBuildSupportError(message: "Unable to find swift compiler executable in search paths")
        }
    }
    
    
    /// Builds the web service.
    /// - Returns: the url of the built executable
    public func buildWebService() throws -> URL {
        switch target {
        case .executable(let url):
            return url
        case let .spmTarget(packageUrl, productName):
            let fileManager = FileManager()
            try fileManager.setWorkingDirectory(to: packageUrl)
            
            let swiftBin = try Self.getSwiftBinUrl()
            let task = Task(
                executableUrl: swiftBin,
                arguments: ["build", "--product", productName],
                outputHandlingMode: .none,
                launchInCurrentProcessGroup: launchChildrenInCurrentProcessGroup
            )
            guard try task.launchSync().exitCode == EXIT_SUCCESS else {
                throw ApodiniDeployBuildSupportError(message: "Unable to build web service")
            }
            let executableUrl = packageUrl
                .appendingPathComponent(".build", isDirectory: true)
                .appendingPathComponent("debug", isDirectory: true)
                .appendingPathComponent(productName, isDirectory: false)
            guard FileManager.default.fileExists(atPath: executableUrl.path) else {
                throw ApodiniDeployBuildSupportError(
                    message: "Unable to locate compiled executable at expected location '\(executableUrl.path)'"
                )
            }
            return executableUrl
        }
    }
    
    
    /// Based on a `WebServiceStructure` as input (i.e. a representation of an entire web service),
    /// computes the default set of nodes within the deployed system.
    public func computeDefaultDeployedSystemNodes(
        from wsStructure: WebServiceStructure,
        nodeIdProvider: (Set<ExportedEndpoint>) -> String = { _ in UUID().uuidString }
    ) throws -> Set<DeployedSystem.Node> {
        guard wsStructure.enabledDeploymentProviders.contains(Self.identifier) else {
            throw ApodiniDeployBuildSupportError(
                message: """
                Identifier of current deployment provider ('\(Self.identifier.rawValue)') not found in set of enabled deployment providers.
                This means that the web service, once deployed, will not be able to load and initialise this deployment provider's runtime.
                """
            )
        }
        
        // a mapping from all user-defined deployment groups, to the set of
        var endpointsByDeploymentGroup = [DeploymentGroup: Set<ExportedEndpoint>](
            uniqueKeysWithValues: wsStructure.deploymentConfig.deploymentGroups.map { ($0, []) }
        )
        // all endpoints which didn't match any of the user-defined deployment groups
        var remainingEndpoints: Set<ExportedEndpoint> = []
        
        for endpoint in wsStructure.endpoints {
            // for each exported endpoint (ie, handler in the DSL), find a matching node, based on the deployment group
            // all groups in which the endpoint would be allowed to be, based on the deployment options
            let matchingGroups = endpointsByDeploymentGroup.keys.filter { $0.matches(exportedEndpoint: endpoint) }
            switch matchingGroups.count {
            case 0:
                // the endpoint didn't match any deployment groups
                remainingEndpoints.insert(endpoint)
            case 1:
                // the endpoint matched exactly one group, so we'll put it in there
                endpointsByDeploymentGroup[matchingGroups[0]]!.insert(endpoint) // swiftlint:disable:this force_unwrapping
            default:
                // the endpoint matched multiple deployment groups, which results in ambiguity, and therefore is forbidden
                throw ApodiniDeployBuildSupportError(
                    message: "Endpoint with handlerId '\(endpoint.handlerId)' matches multiple deployment groups: \(matchingGroups.map({ "'\($0.id)'" }).joined(separator: ", "))"
                )
            }
        }
        
        // The nodes w/in the deployed system
        var nodes: Set<DeployedSystem.Node> = []
        
        // one node per deployment group
        nodes += try endpointsByDeploymentGroup.map { deploymentGroup, endpoints in
            try DeployedSystem.Node(
                id: deploymentGroup.id,
                exportedEndpoints: endpoints,
                userInfo: nil,
                userInfoType: Null.self
            )
        }
        
        switch wsStructure.deploymentConfig.defaultGrouping {
        case .separateNodes:
            nodes += try remainingEndpoints.map { endpoint in
                try DeployedSystem.Node(
                    id: nodeIdProvider([endpoint]),
                    exportedEndpoints: [endpoint],
                    userInfo: nil,
                    userInfoType: Null.self
                )
            }
        case .singleNode:
            nodes.insert(try DeployedSystem.Node(
                id: nodeIdProvider(remainingEndpoints),
                exportedEndpoints: remainingEndpoints,
                userInfo: nil,
                userInfoType: Null.self
            ))
        }
        
        try nodes.assertHandlersLimitedToSingleNode()
        try nodes.assertContainsAllEndpointsIn(wsStructure.endpoints)
        return nodes
    }
}


extension DeploymentGroup {
    // whether this group should contain the exported endpoint
    func matches(exportedEndpoint: ExportedEndpoint) -> Bool {
        handlerTypes.contains(exportedEndpoint.handlerType) || handlerIds.contains(exportedEndpoint.handlerId)
    }
}


extension Sequence where Element == DeployedSystem.Node {
    // check that, in the sequence of nodes, every handler appears in only one node
    func assertHandlersLimitedToSingleNode() throws {
        var exportedHandlerIds = Set<AnyHandlerIdentifier>()
        // make sure a handler isn't listed in multiple nodes
        for node in self {
            for endpoint in node.exportedEndpoints {
                guard exportedHandlerIds.insert(endpoint.handlerId).inserted else {
                    throw ApodiniDeployBuildSupportError(
                        message: "Handler with id '\(endpoint.handlerId)' appears in multiple deployment groups, which is illegal."
                    )
                }
            }
        }
    }
    
    // check that the sequence of nodes contains all endpoints from the other set
    func assertContainsAllEndpointsIn(_ allEndpoints: Set<ExportedEndpoint>) throws {
        // make sure every handler appears in one node
        let exportedHandlerIds = Set(self.flatMap(\.exportedEndpoints).map(\.handlerId))
        let expectedHandlerIds = Set(allEndpoints.map(\.handlerId))
        guard expectedHandlerIds == exportedHandlerIds else {
            assert(exportedHandlerIds.isSubset(of: expectedHandlerIds))
            // All handler ids which appear in one of the two sets, but not in both.
            // Since the set of exported handler ids is a subset of the set of all handler ids,
            // this difference is the set of all handlers which aren't exported by a node
            let diff = expectedHandlerIds.symmetricDifference(exportedHandlerIds)
            throw ApodiniDeployBuildSupportError(
                message: "Handler ids\(diff.map { "'\($0.rawValue)'" }.joined(separator: ", "))"
            )
        }
    }
}
