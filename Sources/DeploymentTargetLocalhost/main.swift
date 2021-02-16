//
//  main.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-31.
//

import Foundation
import ApodiniDeployBuildSupport
import ApodiniUtils
import ArgumentParser
import Logging
import DeploymentTargetLocalhostCommon
import OpenAPIKit



struct DeployError: Swift.Error {
    let message: String
}



private struct LocalhostDeploymentProviderCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Localhost Apodini deployment provider",
        discussion: """
            Deploys an Apodini web service to localhost, mapping the deployed system's nodes to independent processes
            """,
        version: String(LocalhostDeploymentProvider.version)
    )
    
    @Argument(help: "Server package root directory")
    var inputServiceRootDirPath: String // TODO rename (same in the lambda one)
    
    @Option(help: "The port on which the API should listen")
    var port: Int = 8080
    
    @Option(help: "The port number for the first child process. TODO explain more")
    var endpointProcessesBasePort: Int = 5000
    
    @Option(help: "Name of the web service's SPM target/product")
    var productName: String // TODO make this optional?
    
    
    mutating func run() throws {
        var DP = LocalhostDeploymentProvider(
            productName: productName,
            packageRootDir: URL(fileURLWithPath: inputServiceRootDirPath).absoluteURL,
            port: port,
            endpointProcessesBasePort: endpointProcessesBasePort
        )
        try DP.run()
    }
}








struct LocalhostDeploymentProvider: DeploymentProvider {
    static let identifier: DeploymentProviderID = LocalhostDeploymentProviderId
    static let version: Version = 1
    
    let productName: String
    let packageRootDir: URL
    
    // Port on which the proxy should listen
    let port: Int
    // Starting number for the started child processes
    let endpointProcessesBasePort: Int
    
    private let FM = FileManager.default
    private let logger = Logger(label: "DeploymentTargetLocalhost")
    
    mutating func run() throws {
        try FM.lk_initialize()
        try FM.lk_setWorkingDirectory(to: packageRootDir)
        
        logger.notice("Compiling target '\(productName)'")
        let executableUrl = try buildWebService()
        logger.notice("Target executable url: \(executableUrl.path)")
        
        logger.notice("Invoking target to generate web service structure")
        let wsStructure = try generateWebServiceStructure()
        
        let nodes = Set(try computeDefaultDeployedSystemNodes(from: wsStructure).enumerated().map { idx, node in
            try node.withUserInfo(LocalhostLaunchInfo(port: self.endpointProcessesBasePort + idx))
        })
        
        let deployedSystem = try DeployedSystemStructure(
            deploymentProviderId: Self.identifier,
            nodes: nodes,
            userInfo: nil,
            userInfoType: Null.self
        )
        
        let deployedSystemStructureFileUrl = FM.lk_getTemporaryFileUrl(fileExtension: "json")
        try deployedSystem.writeTo(url: deployedSystemStructureFileUrl)
        
        for node in deployedSystem.nodes {
            let task = Task(
                executableUrl: executableUrl,
                arguments: [WellKnownCLIArguments.launchWebServiceInstanceWithCustomConfig, deployedSystemStructureFileUrl.path, node.id],
                launchInCurrentProcessGroup: true,
                environment: [WellKnownEnvironmentVariables.currentNodeId: node.id]
            )
            // TODO detect the children exiting, and either:
            // - kill all others once one of them dies (would be useful if they're all crashing on launch)
            // - relaunch the exited child (would be useful if a child exits due to a fatal error)
            try task.launchAsync()
            let LLI = node.readUserInfo(as: LocalhostLaunchInfo.self)!
            logger.notice("node \(node.id) w/ pid \(task.pid) listening at :\(LLI.port). exported endpoints: \(node.exportedEndpoints.map(\.handlerId))")
        }
                
        logger.notice("Starting proxy server")
        let proxyServer = try ProxyServer(
            openApiDocument: try JSONDecoder().decode(OpenAPI.Document.self, from: wsStructure.openApiDefinition),
            deployedSystem: deployedSystem
        )
        try proxyServer.run(port: self.port)
        logger.notice("exit.")
        return
    }
}


LocalhostDeploymentProviderCLI.main()
