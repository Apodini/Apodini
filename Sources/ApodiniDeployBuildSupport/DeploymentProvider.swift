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



public struct DeploymentProviderID: RawRepresentable, Hashable, Equatable, Codable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}




public typealias Version = Int // TODO this could use the Version type from apodini!



public protocol DeploymentProvider {
    /// This deployment provider's identifier. Must be unique. Use reverse DNS or something like that
    static var identifier: DeploymentProviderID { get }
    
    static var version: Version { get }
    
    /// Path of the web service package's root directory
    var packageRootDir: URL { get }
    
    /// Name of the executable target in the web service's swift package we should deploy
    var productName: String { get }
    
//    init()
}


extension DeploymentProvider {
    public var identifier: DeploymentProviderID { Self.identifier }
}



struct ApodiniDeploySupportError: Swift.Error { // TODO make this error type public? or even remove and/or replace it?
    let message: String
}


extension DeploymentProvider {
    private func getSwiftBinUrl() throws -> URL {
        if let swiftBin = Task.findExecutable(named: "swift") {
            return swiftBin
        } else {
            throw ApodiniDeploySupportError(message: "unable to find swift compiler executable in search paths")
        }
    }
    
    
    /// Builds the web service.
    /// - Returns: the url of the built executable
    public func buildWebService() throws -> URL {
        let FM = FileManager.default
        try FM.lk_setWorkingDirectory(to: packageRootDir)
        
        let swiftBin = try getSwiftBinUrl()
        let task = Task(
            executableUrl: swiftBin,
            arguments: ["build", "--product", productName],
            captureOutput: false,
            launchInCurrentProcessGroup: true
        )
        guard try task.launchSync().exitCode == EXIT_SUCCESS else {
            throw ApodiniDeploySupportError(message: "Unable to build web service")
        }
        let executableUrl = packageRootDir
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent("debug", isDirectory: true)
            .appendingPathComponent(productName, isDirectory: false)
        guard FileManager.default.fileExists(atPath: executableUrl.path) else {
            throw ApodiniDeploySupportError(message: "Unable to locate compiled executable at expected location '\(executableUrl.path)'")
        }
        return executableUrl
    }
    
    
    // TODO rename to generateDefaultWebServiceStructure or smth like that to indicate that this is the default implementation
    // like, onCurrentMachine, inCurrentProcessContext, forCurrentArch, etc
    public func generateWebServiceStructure() throws -> WebServiceStructure {
        let FM = FileManager.default
        let logger = Logger(label: "ApodiniDeployCLI.Localhost")
        
        let swiftBin = try getSwiftBinUrl()
        try FM.lk_setWorkingDirectory(to: packageRootDir)
        
        logger.trace("\(packageRootDir)")
        
        guard FM.lk_directoryExists(atUrl: packageRootDir) else {
            throw ApodiniDeploySupportError(message: "unable to find input directory")
        }
        
        let packageSwiftFileUrl = packageRootDir.appendingPathComponent("Package.swift")
        guard FM.fileExists(atPath: packageSwiftFileUrl.path) else {
            throw ApodiniDeploySupportError(message: "unable to find Package.swift")
        }
        
        let modelFileUrl = FM.temporaryDirectory.appendingPathComponent("AM_\(UUID().uuidString).json")
        guard FM.createFile(atPath: modelFileUrl.path, contents: nil, attributes: nil) else {
            throw ApodiniDeploySupportError(message: "Unable to create file")
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
            throw ApodiniDeploySupportError(message: "Unable to generate model structure")
        }
        
        logger.notice("model written to '\(modelFileUrl)'")
        
        let data = try Data(contentsOf: modelFileUrl, options: [])
        return try JSONDecoder().decode(WebServiceStructure.self, from: data)
    }
    
    
    
    
    public func computeDefaultDeployedSystemNodes(
        from wsStructure: WebServiceStructure,
        nodeIdProvider: (Set<ExportedEndpoint>) -> String = { _ in UUID().uuidString }
    ) throws -> Set<DeployedSystemConfiguration.Node> {
        // TODO how should this handle the same endpoint id being in multiple groups
        // also needs validation to make sure all handler ids specified in groups actually exist in the WS
        
        //var nodes: [DeployedSystemConfiguration.Node] = []
        
        let getEndpointById: (String) -> ExportedEndpoint? = { id in
            wsStructure.endpoints.first { $0.handlerIdRawValue == id }
        }
        
        
        // a mapping from all user-defined deployment groups, to the set of
        var endpointsByDeploymentGroup = Dictionary<DeploymentGroup, Set<ExportedEndpoint>>(
            uniqueKeysWithValues: wsStructure.deploymentConfig.deploymentGroups.groups.map { ($0, []) }
        )
        // all endpoints which didn't match any of the user-defined deployment groups
        var remainingEndpoints: Set<ExportedEndpoint> = []
        
        
        for endpoint in wsStructure.endpoints {
            // for each exported endpoint (ie, handler in the DSL), find a matching node, based on the deployment group
            if let DG = endpointsByDeploymentGroup.keys.first(where: { $0.matches(exportedEndpoint: endpoint) }) {
                endpointsByDeploymentGroup[DG]!.insert(endpoint)
            } else {
                remainingEndpoints.insert(endpoint)
            }
        }
        
        
        // The nodes w/in the deployed system
        var nodes: Set<DeployedSystemStructure.Node> = []
        
        // one node per deployment group
        nodes += try endpointsByDeploymentGroup.map { deploymentGroup, endpoints in
            try DeployedSystemStructure.Node(
                id: deploymentGroup.id,
                exportedEndpoints: endpoints,
                userInfo: nil, // TODO experiment w/ Null() what does the json look like? why does it (?sometimes?) seem to use an empty object instead of the null literal?
                userInfoType: Null.self
            )
        }
        
        switch wsStructure.deploymentConfig.deploymentGroups.defaultGrouping {
        case .separateNodes:
            nodes += try remainingEndpoints.map { endpoint in
                try DeployedSystemStructure.Node(
                    id: nodeIdProvider([endpoint]),
                    exportedEndpoints: [endpoint],
                    userInfo: nil,
                    userInfoType: Null.self
                )
            }
        case .singleNode:
            nodes.insert(try DeployedSystemStructure.Node(
                id: nodeIdProvider(remainingEndpoints),
                exportedEndpoints: remainingEndpoints,
                userInfo: nil,
                userInfoType: Null.self
            ))
        }
        
//        // one node per deployment group
//        try nodes += wsStructure.deploymentConfig.deploymentGroups.groups.map { deploymentGroup in
//            try DeployedSystemConfiguration.Node(
//                id: deploymentGroup.id,
//                exportedEndpoints: deploymentGroup.handlerIds.map { getEndpointById($0)! },
//                userInfo: nil, // TODO experiment w/ Null() what does the json look like? why does it (?sometimes?) seem to use an empty object instead of the null literal?
//                userInfoType: Null.self
//            )
//        }
//
//        // Create nodes for the remaining endpoints
//        let remainingEndpoints: [ExportedEndpoint] = wsStructure.endpoints
//            .filter { endpoint in !nodes.contains { $0.exportedEndpoints.contains(endpoint) } }
//
//        switch wsStructure.deploymentConfig.deploymentGroups.defaultGrouping {
//        case .singleNode:
//            let node = try DeployedSystemConfiguration.Node(
//                id: nodeIdProvider(remainingEndpoints),
//                exportedEndpoints: remainingEndpoints,
//                userInfo: Null()
//            )
//            nodes.append(node)
//        case .separateNodes:
//            try nodes += remainingEndpoints.map { endpoint in
//                try DeployedSystemConfiguration.Node(
//                    id: nodeIdProvider([endpoint]),
//                    exportedEndpoints: [endpoint],
//                    userInfo: Null()
//                )
//            }
//        }
        
        do {
            var exportedHandlerIds = Set<String>()
            // make sure a handler isn't listed in multiple nodes
            for node in nodes {
                for endpoint in node.exportedEndpoints {
                    guard exportedHandlerIds.insert(endpoint.handlerIdRawValue).inserted else {
                        throw NSError.apodiniDeploy(
                            localizedDescription: "Handler with id '\(endpoint.handlerIdRawValue)' appears in multiple deployment groups, which is illegal."
                        )
                    }
                }
            }
            // make sure every handler appears in one node
            let allHandlerIds = Set(wsStructure.endpoints.map(\.handlerIdRawValue))
            guard allHandlerIds == exportedHandlerIds else {
                assert(exportedHandlerIds.isSubset(of: allHandlerIds))
                // All handler ids which appear in one of the two sets, but not in both.
                // Since the set of exported handler ids is a subset of the set of all handler ids,
                // this difference is the set of all handlers which aren't exported by a node
                let diff = allHandlerIds.symmetricDifference(exportedHandlerIds)
                throw NSError.apodiniDeploy(
                    localizedDescription: "Handler ids\(diff.map({ "'\($0)'" }).joined(separator: ", "))"
                )
            }
        }
        
        return nodes
    }
}



extension DeploymentGroup {
    // whether this group should contain the exported endpoint
    func matches(exportedEndpoint: ExportedEndpoint) -> Bool {
        switch self.inputKind {
        case .handlerId:
            return self.input.contains(exportedEndpoint.handlerIdRawValue)
        case .handlerType:
            return self.input.contains(exportedEndpoint.handlerType)
        }
    }
}



extension Set {
    /// insert an element into the set
    public static func += (lhs: inout Set<Element>, rhs: Element) {
        lhs.insert(rhs)
    }
    
    /// insert a sequence of elements into the set
    public static func += <S> (lhs: inout Self, rhs: S) where S: Sequence, S.Element == Element {
        lhs.formUnion(rhs)
    }
}
