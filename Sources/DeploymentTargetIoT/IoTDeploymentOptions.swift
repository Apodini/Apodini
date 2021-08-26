//
//  File.swift
//  File
//
//  Created by Felix Desiderato on 13/08/2021.
//

import Foundation
import ArgumentParser

public struct IoTDeploymentOptions: ParsableArguments {
    @Option(help: "The path to the configuration file that contains infos to the searchable types, such as usernames and passwords")
    public var configurationFilePath: String = ""

    @Option(help: "The type ids that should be searched for")
    public var types: [String] = ["_workstation._tcp."]

    @Argument(help: "Directory containing the Package.swift with the to-be-deployed web service's target")
    public var inputPackageDir: String = "/Users/felice/Documents/ApodiniDemoWebService"

    @Option(help: "Name of the web service's SPM target/product")
    public var productName: String = "TestWebService"

    @Option(help: "Remote directory of deployment")
    public var deploymentDir: String = "/usr/deployment"
    
    @Flag(help: "If set, the deployment provider listens for changes in the the working directory and automatically redeploys changes to the affected nodes.")
    public var automaticRedeployment = false
    
    @Argument(parsing: .unconditionalRemaining, help:"CLI arguments of the web service")
    var webServiceArguments: [String] = []
    
    public init() {}
}
