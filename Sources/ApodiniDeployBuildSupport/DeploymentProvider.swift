//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-31.
//


import Foundation
import Logging
#if os(Linux)
import Glibc
#else
import Darwin
#endif


import Apodini
import ApodiniUtils



public struct DeploymentProviderID: RawRepresentable, Hashable, Equatable, Codable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}




public protocol DeploymentProvider {
    typealias Version = UInt
    
    /// This deployment provider's identifier. Must be unique. Use reverse DNS or something like that
    static var identifier: DeploymentProviderID { get }
    
    static var version: Version { get }
    
    /// Path of the web service package's root directory
    var packageRootDir: URL { get }
    
    /// Name of the executable target in the web service's swift package we should deploy
    var productName: String { get }
}


extension DeploymentProvider {
    public var identifier: DeploymentProviderID { Self.identifier }
    public var version: Version { Self.version }
}



struct ApodiniDeployBuildSupportError: Swift.Error {
    let message: String
}


extension DeploymentProvider {
    private func getSwiftBinUrl() throws -> URL {
        if let swiftBin = Task.findExecutable(named: "swift") {
            return swiftBin
        } else {
            throw ApodiniDeployBuildSupportError(message: "Unable to find swift compiler executable in search paths")
        }
    }
    
    
    /// Builds the web service.
    /// - Returns: the url of the built executable
    public func buildWebService() throws -> URL {
        let FM = FileManager.default
        try FM.setWorkingDirectory(to: packageRootDir)
        
        let swiftBin = try getSwiftBinUrl()
        let task = Task(
            executableUrl: swiftBin,
            arguments: ["build", "--product", productName],
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        guard try task.launchSync().exitCode == EXIT_SUCCESS else {
            throw ApodiniDeployBuildSupportError(message: "Unable to build web service")
        }
        let executableUrl = packageRootDir
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
    
    
    public func generateDefaultWebServiceStructure() throws -> WebServiceStructure {
        let FM = FileManager.default
        let logger = Logger(label: "ApodiniDeployCLI.Localhost")
        
        let swiftBin = try getSwiftBinUrl()
        try FM.setWorkingDirectory(to: packageRootDir)
        
        logger.trace("\(packageRootDir)")
        
        guard FM.directoryExists(atUrl: packageRootDir) else {
            throw ApodiniDeployBuildSupportError(message: "Unable to find input directory")
        }
        
        let packageSwiftFileUrl = packageRootDir.appendingPathComponent("Package.swift")
        guard FM.fileExists(atPath: packageSwiftFileUrl.path) else {
            throw ApodiniDeployBuildSupportError(message: "Unable to find Package.swift")
        }
        
        let modelFileUrl = FM.temporaryDirectory.appendingPathComponent("AM_\(UUID().uuidString).json")
        guard FM.createFile(atPath: modelFileUrl.path, contents: nil, attributes: nil) else {
            throw ApodiniDeployBuildSupportError(message: "Unable to create file")
        }
        
        let exportWebServiceModelTask = Task(
            executableUrl: swiftBin,
            arguments: [
                "run",
                productName,
                WellKnownCLIArguments.exportWebServiceModelStructure,
                modelFileUrl.path
            ],
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        logger.notice("Invoking child process `\(exportWebServiceModelTask.taskStringRepresentation)`")
        let terminationInfo = try exportWebServiceModelTask.launchSync()
        guard terminationInfo.exitCode == EXIT_SUCCESS else {
            throw ApodiniDeployBuildSupportError(message: "Unable to generate model structure")
        }
        
        logger.notice("model written to '\(modelFileUrl)'")
        
        let data = try Data(contentsOf: modelFileUrl, options: [])
        return try JSONDecoder().decode(WebServiceStructure.self, from: data)
    }
    
    
    
    
    public func computeDefaultDeployedSystemNodes(
        from wsStructure: WebServiceStructure,
        nodeIdProvider: (Set<ExportedEndpoint>) -> String = { _ in UUID().uuidString }
    ) throws -> Set<DeployedSystem.Node> {
        // a mapping from all user-defined deployment groups, to the set of
        var endpointsByDeploymentGroup = Dictionary<DeploymentGroup, Set<ExportedEndpoint>>(
            uniqueKeysWithValues: wsStructure.deploymentConfig.deploymentGroups.groups.map { ($0, []) }
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
                endpointsByDeploymentGroup[matchingGroups[0]]!.insert(endpoint)
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
                userInfo: Null()
            )
        }
        
        switch wsStructure.deploymentConfig.deploymentGroups.defaultGrouping {
        case .separateNodes:
            nodes += try remainingEndpoints.map { endpoint in
                try DeployedSystem.Node(
                    id: nodeIdProvider([endpoint]),
                    exportedEndpoints: [endpoint],
                    userInfo: Null()
                )
            }
        case .singleNode:
            nodes.insert(try DeployedSystem.Node(
                id: nodeIdProvider(remainingEndpoints),
                exportedEndpoints: remainingEndpoints,
                userInfo: Null()
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
                message: "Handler ids\(diff.map({ "'\($0.rawValue)'" }).joined(separator: ", "))"
            )
        }
    }
}
