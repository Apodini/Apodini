//
//  DeploymentCLI.swift
//  
//
//  Created by Felix Desiderato on 30/06/2021.
//

import Foundation
import ArgumentParser

private var _configuration = CommandConfiguration(
    commandName: "deploy",
    abstract: "Apodini deployment provider",
    discussion: """
    Deploys an Apodini web service to the specified target.
    """,
    version: "0.0.2",
    subcommands: []
)

//apodini deploy local -inputDir
public struct DeploymentCLI: ParsableCommand {
    public static var configuration: CommandConfiguration {
        _configuration
    }

    public static func commands(_ commands: ParsableCommand.Type...) -> DeploymentCLI.Type {
        _configuration.subcommands = commands
        return DeploymentCLI.self
    }

    public init() {}
}
