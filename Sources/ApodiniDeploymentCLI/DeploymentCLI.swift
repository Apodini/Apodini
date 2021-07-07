//
//  DeploymentCLI.swift
//  
//
//  Created by Felix Desiderato on 30/06/2021.
//

import Foundation
import ArgumentParser

/// Enables the deployment of an Apodini web service via command line. Can be added as a subcommand to the `configuration: CommandConfiguration` property of a web service.
public struct DeploymentCLI: ParsableCommand {
    public static var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "deployment",
        abstract: "Apodini deployment provider",
        discussion: """
        Deploys an Apodini web service to the specified target.
        """,
        version: "0.0.2",
        subcommands: []
    )

    /// Allows to dynamically add subcommands to the `deployment` command.
    /// Use this to add custom deployment provider or use existing ones, such as `LambdaDeploymentProviderCLI`.
    public static func commands(_ commands: ParsableCommand.Type...) -> DeploymentCLI.Type {
        configuration.subcommands = commands
        return DeploymentCLI.self
    }

    public init() {}
}
