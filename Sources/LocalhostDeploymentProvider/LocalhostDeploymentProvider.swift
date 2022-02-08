//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import ApodiniDeployerBuildSupport
import ApodiniUtils
import ArgumentParser
import Logging
import LocalhostDeploymentProviderCommon
import OpenAPIKit


@main
private struct LocalhostDeploymentProviderCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Localhost Apodini Deployment Provider",
        discussion: """
            Deploys an Apodini web service to localhost, mapping the deployed system's nodes to independent processes.
            """,
        version: "0.0.1"
    )
    
    @Argument(help: "Directory containing the Package.swift with the to-be-deployed web service's target")
    var inputPackageDir: String
    
    @Option(help: "The port on which the API should listen")
    var port: Int = 80
    
    @Option(help: "The port number for the first-launched child process")
    var endpointProcessesBasePort: Int = 52000
    
    @Option(help: "Name of the web service's SPM target/product")
    var productName: String
    
    @Argument(parsing: .unconditionalRemaining, help:"CLI arguments of the web service")
    var webServiceArguments: [String] = []
    
    mutating func run() throws {
        let deploymentProvider = LocalhostDeploymentProvider(
            productName: productName,
            packageRootDir: URL(fileURLWithPath: inputPackageDir).absoluteURL,
            port: port,
            endpointProcessesBasePort: endpointProcessesBasePort,
            webServiceArguments: webServiceArguments
        )
        try deploymentProvider.run()
    }
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
    
    let webServiceArguments: [String]
    
    private let fileManager = FileManager.default
    private let logger = Logger(label: "LocalhostDeploymentProvider")
    
    private let programLifetime = ProgramLifetimeManager()
    
    func run() throws {
        try fileManager.initialize()
        try fileManager.setWorkingDirectory(to: packageRootDir)
        
        logger.notice("Compiling target '\(productName)'")
        let executableUrl = try buildWebService()
        logger.notice("Target executable url: \(executableUrl.path)")
        
        logger.notice("Invoking target with arguments to generate web service structure")

        let (modelFileUrl, deployedSystem) = try retrieveSystemStructure(
            executableUrl,
            providerCommand: "local",
            additionalCommands: [
                "--identifier",
                Self.identifier.rawValue,
                "--endpoint-processes-base-port",
                "\(self.endpointProcessesBasePort)"
            ],
            webServiceCommands: webServiceArguments,
            as: LocalhostDeployedSystem.self
        )
        
        var observers: [AnyObject] = []

        for node in deployedSystem.nodes {
            let task = ChildProcess(
                executableUrl: executableUrl,
                arguments: webServiceArguments + [
                    "deploy",
                    "startup",
                    "local",
                    modelFileUrl.path,
                    node.id
                ],
                redirectStderrToStdout: true,
                launchInCurrentProcessGroup: true
            )
            observers.append(task.observeOutput { stdioType, data, task in
                print("[ChildIO] \(stdioType), \(String(data: data, encoding: .utf8) ?? "ERROR"), task: \(task)")
            })
            func taskTerminationHandler(_ terminationInfo: ChildProcess.TerminationInfo) {
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
                    ChildProcess.killAllInChildrenInProcessGroup()
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
        let proxyServer: ProxyServer
        do {
            proxyServer = try ProxyServer(
                openApiDocument: deployedSystem.openApiDocument,
                deployedSystem: deployedSystem,
                port: self.port
            )
            try proxyServer.start()
        } catch {
            // An error occurred while initialising or starting the server
            ChildProcess.killAllInChildrenInProcessGroup()
            throw error
        }
        try programLifetime.start(on: proxyServer.eventLoopGroup.next()).wait()
        ChildProcess.killAllInChildrenInProcessGroup() // just to be safe
        do {
            try proxyServer.stop()
            logger.notice("Did shut down proxy server")
        } catch {
            logger.error("Error when trying to stop proxy server: \(error)")
        }
    }
}
