//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//    

import Foundation
import ArgumentParser
import Apodini
import ApodiniDeployRuntimeSupport
import DeploymentTargetAWSLambdaCommon

public struct LambdaStartupCommand<Service: WebService>: DeploymentStartupCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "aws",
            abstract: "Start a web service - AWS Lambda",
            discussion: "Starts up an Apodini web service for the aws lambda deployment",
            version: "0.0.1"
        )
    }

    @ArgumentParser.Argument(help: "The location of the json containing the system structure")
    public var filePath: String
    
    @ArgumentParser.Option(help: "The identifier of the deployment node")
    public var nodeId: String

    public var deployedSystem: AnyDeployedSystem.Type {
        LambdaDeployedSystem.self
    }
    
    public func run() throws {
        let app = Application()
        
        app.storage.set(DeploymentStartUpStorageKey.self, to: self)
        try Service.start(app: app, webService: Service())
    }

    public init() {}
}
