//
//  LocalhostDeploymentCLI.swift
//  
//
//  Created by Felix Desiderato on 02/07/2021.
//

import Foundation
import Apodini
import ArgumentParser


public struct LocalhostDeploymentCLI<WebService: Apodini.WebService>: ParsableCommand {
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
    
    @Option(help: "The port on which the API should listen")
    var port: Int = 8080
    
    @Option(help: "The port number for the first-launched child process")
    var endpointProcessesBasePort: Int = 5000
    
    
    public init() {}
    
    public mutating func run() throws {
        let service = WebService()
        service.runSyntaxTreeVisitor()
        
        let deploymentProvider = LocalhostDeploymentProvider(
            executableUrl: ProcessInfo.processInfo.executableUrl,
            port: port,
            endpointProcessesBasePort: endpointProcessesBasePort
        )
        try deploymentProvider.run()
    }
}
