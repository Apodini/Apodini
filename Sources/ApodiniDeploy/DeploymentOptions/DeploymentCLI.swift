//
//  DeploymentCLI.swift
//  
//
//  Created by Felix Desiderato on 30/06/2021.
//

import Foundation
import ArgumentParser
import DeploymentTargetLocalhost
import DeploymentTargetAWSLambda
import ApodiniDeployBuildSupport

//apodini deploy local -inputDir
public struct DeploymentCLI<Service: Apodini.WebService>: ParsableCommand {
    
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "deploy",
            abstract: "Apodini deployment provider",
            discussion: """
            Deploys an Apodini web service to the specified target.
            """,
            version: "0.0.2",
            subcommands: [LocalHostCLI<Service>.self, AWSLambdaCLI<Service>.self]
        )
    }
    
    struct Options: ParsableArguments {
        @Argument(help: "Directory containing the Package.swift with the to-be-deployed web service's target")
        var inputPackageDir: String
        
        @Option(help: "Name of the web service's SPM target/product")
        var productName: String
    }
    
    public init() {}
}
