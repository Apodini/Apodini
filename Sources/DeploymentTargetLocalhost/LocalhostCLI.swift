//
//  LocalHostCLI.swift
//  
//
//  Created by Felix Desiderato on 02/07/2021.
//

import Foundation
import ArgumentParser
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
    
    @Argument(help: "Directory containing the Package.swift with the to-be-deployed web service's target")
    var inputPackageDir: String
    
    @Option(help: "Name of the web service's SPM target/product")
    var productName: String
    
    @Option(help: "The port on which the API should listen")
    var port: Int = 8080
    
    @Option(help: "The port number for the first-launched child process")
    var endpointProcessesBasePort: Int = 5000
    
    public mutating func run() throws {
        let service = Service()
        service.runSyntaxTreeVisitor()
        
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
