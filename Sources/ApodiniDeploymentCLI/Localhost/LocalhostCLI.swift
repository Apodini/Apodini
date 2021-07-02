//
//  File.swift
//  
//
//  Created by Felix Desiderato on 02/07/2021.
//

import Foundation
import ArgumentParser
import DeploymentTargetLocalhost
import Apodini

public struct LocalHostCLI<Service: Apodini.WebService>: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "local",
            abstract: "Localhost Apodini deployment provider",
            discussion: """
            Deploys an Apodini web service to localhost, mapping the deployed system's nodes to independent processes.
            """,
            version: "0.0.2"
        )
    }
    
    @OptionGroup
    var options: DeploymentCLI<Service>.Options
    
    @Option(help: "The port on which the API should listen")
    var port: Int = 8080
    
    @Option(help: "The port number for the first-launched child process")
    var endpointProcessesBasePort: Int = 5000
    
    public mutating func run() throws {
        let service = Service()
        service.runSyntaxTreeVisitor()
        
        let deploymentProvider = LocalhostDeploymentProvider(
            productName: options.productName,
            packageRootDir: URL(fileURLWithPath: options.inputPackageDir).absoluteURL,
            port: port,
            endpointProcessesBasePort: endpointProcessesBasePort
        )
        try deploymentProvider.run()
    }
    
    public init() {}
}
