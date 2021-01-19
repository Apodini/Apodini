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
    
    init()
}


extension DeploymentProvider {
    public var identifier: DeploymentProviderID { Self.identifier }
}



enum ApodiniDeploySupportError: Error {
    case other(String)
}


extension DeploymentProvider {
    private func getSwiftBinUrl() throws -> URL {
        if let swiftBin = Task.findExecutable(named: "swift") {
            return swiftBin
        } else {
            throw ApodiniDeploySupportError.other("unable to find swift compiler executable in search paths")
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
            throw ApodiniDeploySupportError.other("Unable to build web service")
        }
        let executableUrl = packageRootDir
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent("debug", isDirectory: true)
            .appendingPathComponent(productName, isDirectory: false)
        guard FileManager.default.fileExists(atPath: executableUrl.path) else {
            throw ApodiniDeploySupportError.other("Unable to locate compiled executable at expected location '\(executableUrl.path)'")
        }
        return executableUrl
    }
    
    
    public func generateWebServiceStructure() throws -> WebServiceStructure {
        let FM = FileManager.default
        let logger = Logger(label: "ApodiniDeployCLI.Localhost")
        
        let swiftBin = try getSwiftBinUrl()
        try FM.lk_setWorkingDirectory(to: packageRootDir)
        
        logger.trace("\(packageRootDir)")
        
        guard FM.lk_directoryExists(atUrl: packageRootDir) else {
            throw ApodiniDeploySupportError.other("unable to find input directory")
        }
        
        let packageSwiftFileUrl = packageRootDir.appendingPathComponent("Package.swift")
        guard FM.fileExists(atPath: packageSwiftFileUrl.path) else {
            throw ApodiniDeploySupportError.other("unable to find Package.swift")
        }
        
        let modelFileUrl = FM.temporaryDirectory.appendingPathComponent("AM_\(UUID().uuidString).json")
        guard FM.createFile(atPath: modelFileUrl.path, contents: nil, attributes: nil) else {
            throw ApodiniDeploySupportError.other("Unable to create file")
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
            throw ApodiniDeploySupportError.other("Unable to generate model structure")
        }
        
        logger.notice("model written to '\(modelFileUrl)'")
        
        let data = try Data(contentsOf: modelFileUrl, options: [])
        return try JSONDecoder().decode(WebServiceStructure.self, from: data)
    }
    
    
    
    
    public func computeDefaultDeployedSystemNodes(from wsStructure: WebServiceStructure) throws -> [DeployedSystemConfiguration.Node] {
        // TODO how should this handle the same endpoint id being in multiple groups
        // also needs validation to make sure all handler ids specified in groups actually exist in the WS
        
        var nodes: [DeployedSystemConfiguration.Node] = []
        
        let getEndpointById: (String) -> ExportedEndpoint? = { id in
            wsStructure.endpoints.first { $0.handlerIdRawValue == id }
        }
        
        // one node per deployment group
        try nodes += wsStructure.deploymentConfig.deploymentGroups.groups.map { deploymentGroup in
            try DeployedSystemConfiguration.Node(
                id: UUID().uuidString,
                exportedEndpoints: deploymentGroup.handlerIds.map { getEndpointById($0)! },
                userInfo: nil, // TODO experiment w/ Null() what does the json look like? why does it (?sometimes?) seem to use an empty object instead of the null literal?
                userInfoType: Null.self
            )
        }
        
        // Create nodes for the remaining endpoints
        let remainingEndpoints: [ExportedEndpoint] = wsStructure.endpoints
            .filter { endpoint in !nodes.contains { $0.exportedEndpoints.contains(endpoint) } }
        
        switch wsStructure.deploymentConfig.deploymentGroups.defaultGrouping {
        case .singleNode:
            let node = try DeployedSystemConfiguration.Node(
                id: UUID().uuidString,
                exportedEndpoints: remainingEndpoints,
                userInfo: Null()
            )
            nodes.append(node)
        case .separateNodes:
            try nodes += remainingEndpoints.map { endpoint in
                try DeployedSystemConfiguration.Node(
                    id: UUID().uuidString,
                    exportedEndpoints: [endpoint],
                    userInfo: Null()
                )
            }
        }
        
        return nodes
    }
}
