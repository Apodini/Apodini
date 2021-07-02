//
//  LocalhostDeploymentProvider.swift
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
import Apodini

public struct LocalHostCLI<Service: Apodini.WebService>: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "local",
            abstract: "Localhost Apodini deployment provider",
            discussion: """
            Deploys an Apodini web service to localhost, mapping the deployed system's nodes to independent processes.
            """,
            version: "0.0.1"
        )
    }
    
//    @OptionGroup
//    var options: Deploy
    
    @Argument(help: "Directory containing the Package.swift with the to-be-deployed web service's target")
    var inputPackageDir: String = "/Users/felice/Documents/ApodiniDemoWebService"
    
    @Option(help: "The port on which the API should listen")
    var port: Int = 8080
    
    @Option(help: "The port number for the first-launched child process")
    var endpointProcessesBasePort: Int = 5000
    
    @Option(help: "Name of the web service's SPM target/product")
    var productName: String = "TestWebService"
    
    mutating public func run() throws {
        let service = Service.init()
        service.runSyntaxTreeVisit()
        
        let deploymentProvider = LocalhostDeploymentProvider(
            productName: productName,
            packageRootDir: URL(fileURLWithPath: inputPackageDir).absoluteURL,
            port: port,
            endpointProcessesBasePort: endpointProcessesBasePort
        )
        try deploymentProvider.run()
    }
    
    public init() {}
}


struct LocalhostDeploymentProvider: DeploymentProvider {
    static let identifier: DeploymentProviderID = localhostDeploymentProviderId
    
    let productName: String
    let packageRootDir: URL
    
    var target: DeploymentProviderTarget {
        .spmTarget(packageUrl: packageRootDir, targetName: productName)
    }
    
    // Port on which the proxy should listen
    let port: Int
    // Starting number for the started child processes
    let endpointProcessesBasePort: Int
    
    private let fileManager = FileManager.default
    private let logger = Logger(label: "DeploymentTargetLocalhost")
    
    func run() throws {
        try fileManager.initialize()
        try fileManager.setWorkingDirectory(to: packageRootDir)
        
        logger.notice("Starting deployment of \(productName)..")
        
        var buildMode: String
        #if DEBUG
        buildMode = "debug"
        #else
        buildMode = "release"
        #endif
        
        let executableUrl = packageRootDir
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent(buildMode, isDirectory: true)
            .appendingPathComponent(productName, isDirectory: false)
        guard FileManager.default.fileExists(atPath: executableUrl.path) else {
            throw ApodiniDeployBuildSupportError(
                message: "Unable to locate compiled executable at expected location '\(executableUrl.path)'"
            )
        }
        
        logger.notice("Target executable url: \(executableUrl.path)")
        
        logger.notice("Retrieve web service structure.")
        let wsStructure = try retrieveWebServiceStructure()
        
        
        let nodes = Set(try computeDefaultDeployedSystemNodes(from: wsStructure).enumerated().map { idx, node in
            try node.withUserInfo(LocalhostLaunchInfo(port: self.endpointProcessesBasePort + idx))
        })
        
        let deployedSystem = try DeployedSystem(
            deploymentProviderId: Self.identifier,
            nodes: nodes,
            userInfo: nil,
            userInfoType: Null.self
        )
        
        let deployedSystemFileUrl = fileManager.getTemporaryFileUrl(fileExtension: "json")
        try deployedSystem.writeJSON(to: deployedSystemFileUrl)
        
        for node in deployedSystem.nodes {
            let task = Task(
                executableUrl: executableUrl,
                launchInCurrentProcessGroup: true,
                environment: [
                    WellKnownEnvironmentVariables.executionMode:
                        WellKnownEnvironmentVariableExecutionMode.launchWebServiceInstanceWithCustomConfig,
                    WellKnownEnvironmentVariables.fileUrl:
                        deployedSystemFileUrl.path,
                    WellKnownEnvironmentVariables.currentNodeId:
                        node.id
                ]
            )
            func taskTerminationHandler(_ terminationInfo: Task.TerminationInfo) {
                switch (terminationInfo.reason, terminationInfo.exitCode) {
                case (.uncaughtSignal, SIGILL):
                    // This seems to be the combination with which a fatalError terminates a program.
                    // If one of the children was terminated with a fatalError, we re-spawn it to keep the server running
                    logger.warning("Restarting child for node '\(node.id)'")
                // Temporarily disabled because this (sometimes?) triggers a compiler bug where swiftc will just hang forever.
                // try! task.launchAsync(taskTerminationHandler)
                //                case (.uncaughtSignal, SIGTERM):
                //                    // The task was terminated
                //                    break
                default:
                    // If one of the children terminated, and it was not caused by a fatalError, we shut down the entire thing
                    logger.warning("Child for node '\(node.id)' terminated unexpectedly. killing everything just to be safe.")
                    Task.killAllInChildrenInProcessGroup()
                }
            }
            try task.launchAsync(taskTerminationHandler)
            guard let launchInfo = node.readUserInfo(as: LocalhostLaunchInfo.self) else {
                // unreachable because we write the exact same type above
                fatalError("Unable to read launch info")
            }
            logger.notice("node \(node.id) w/ pid \(task.pid) listening at :\(launchInfo.port). exported endpoints: \(node.exportedEndpoints.map(\.handlerId))")
        }
        
        logger.notice("Starting proxy server")
        do {
            let proxyServer = try ProxyServer(
                openApiDocument: wsStructure.openApiDocument,
                deployedSystem: deployedSystem
            )
            try proxyServer.run(port: self.port)
        } catch {
            Task.killAllInChildrenInProcessGroup()
            throw error
        }
        logger.notice("exit.")
        return
    }
}
