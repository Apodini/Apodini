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

/// The default `DeploymentStartupCommand` of the localhost deployment provider. This command is responsible for
/// starting the web service on a deployment node taking into account the specifications given by`LambdaDeploymentProvider`.
/// These commands are added to Apodini by default.
/// The user should only added this command manually if he uses a custom `CommandConfiguration` in his web service.
/// The command needs to be added following this pattern for the providers to work:
///  `ApodiniDeployCommand.withSubcommands(
///         `StartupCommand.withSubcommands(
///             `LambdaStartupCommand.self`,
///         `    ... any other startup commands you want to use
///          `)`
///  `)`
public struct LambdaStartupCommand<Service: WebService>: DeploymentStartupCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "aws-lambda",
            abstract: "Start a web service - AWS Lambda",
            discussion: "Starts up an Apodini web service for the aws lambda deployment",
            version: "0.0.1"
        )
    }

    @ArgumentParser.Argument(help: "The location of the json containing the system structure")
    public var filePath: String
    
    @ArgumentParser.Argument(help: "The identifier of the deployment node")
    public var nodeId: String
    
    @ArgumentParser.OptionGroup
    public var webServiceWithArguments: Service

    public var deployedSystemType: AnyDeployedSystem.Type {
        LambdaDeployedSystem.self
    }
    
    public init() {}
    
    public func run() throws {
        let app = Application()
        app.storage.set(DeploymentStartUpStorageKey.self, to: self)
        try webServiceWithArguments.start(mode: .run, app: app)
    }
}
