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


private struct LocalhostDeploymentProviderCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Localhost Apodini deployment provider",
        discussion: """
            Deploys an Apodini web service to localhost, mapping the deployed system's nodes to independent processes
            """,
        version: String(LocalhostDeploymentProvider.version)
    )
    
    @Argument(help: "Directory containing the Package.swift with the to-be-deployed web service's target")
    var inputPackageDir: String
    
    @Option(help: "The port on which the API should listen")
    var port: Int = 8080
    
    @Option(help: "The port number for the first-launched child process")
    var endpointProcessesBasePort: Int = 5000
    
    @Option(help: "Name of the web service's SPM target/product")
    var productName: String
    
    
    mutating func run() throws {
        var deploymentProvider = LocalhostDeploymentProvider(
            productName: productName,
            packageRootDir: URL(fileURLWithPath: inputPackageDir).absoluteURL,
            port: port,
            endpointProcessesBasePort: endpointProcessesBasePort
        )
        try deploymentProvider.run()
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
        let wsStructure = try generateDefaultWebServiceStructure()
        
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
        try deployedSystem.writeJSON(to: deployedSystemStructureFileUrl)
        
        for node in deployedSystem.nodes {
            let task = Task(
                executableUrl: executableUrl,
                arguments: [WellKnownCLIArguments.launchWebServiceInstanceWithCustomConfig, deployedSystemStructureFileUrl.path, node.id],
                launchInCurrentProcessGroup: true,
                environment: [WellKnownEnvironmentVariables.currentNodeId: node.id]
            )
            func taskTerminationHandler(_ terminationInfo: Task.TerminationInfo) {
                if terminationInfo.exitCode == 4 && terminationInfo.reason == .uncaughtSignal {
                    // This seems to be the combination with which a fatalError terminates a program.
                    // If one of the children was terminated with a fatalError, we re-spawn it to keep the server running
                    // TODO implement! (this is what triggers the compiler bug)
                    logger.warning("Restarting child for node '\(node.id)'")
                    // try! task.launchAsync(taskTerminationHandler)
                } else {
                    // If one of the children terminated, and it was not caused by a fatalError, we shut down the entire thing
                    logger.warning("Child for node '\(node.id)' terminated unexpectedly. killing everything just to be safe.")
                    exit(EXIT_FAILURE)
                }
            }
            // try task.launchAsync(taskTerminationHandler)
            guard let launchInfo = node.readUserInfo(as: LocalhostLaunchInfo.self) else {
                // unreachable because we write the exact same type above
                fatalError("Unable to read launch info")
            }
            logger.notice("node \(node.id) w/ pid \(task.pid) listening at :\(launchInfo.port). exported endpoints: \(node.exportedEndpoints.map(\.handlerId))")
        }
        
        logger.notice("Starting proxy server")
        let proxyServer = try ProxyServer(
            openApiDocument: wsStructure.openApiDocument,
            deployedSystem: deployedSystem
        )
        try proxyServer.run(port: self.port)
        logger.notice("exit.")
        return
    }
}


LocalhostDeploymentProviderCLI.main()
