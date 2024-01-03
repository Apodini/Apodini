//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//        

import Foundation
import ArgumentParser

/// A basic CLI command containing subcommands that are needed for deployment related actions.
/// The invokation of this command does nothing. Consider looking at `ExportStructureCommand` for possible use cases.
/// This command or its subcommands should not be called directly by the user, but rather by a Deployment Provider.
/// This command is added to the Apodini CLI by default. If you override `CommandConfiguration` of your web service
/// and want to use a Deployment Provider, please make sure to add this manually as a `subcommand`.
public struct ApodiniDeployerCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "deploy",
        abstract: "Apodini Deployment Provider",
        discussion: """
             Offers utilities for the deployment of an Apodini web service
             """,
        version: "0.3.0"
    )
    
    public init() {}
    
    public func run() throws {
        ApodiniDeployerCommand.helpMessage(columns: nil)
        ApodiniDeployerCommand.exit(withError:
                                    ApodiniDeployerError(message: "Calling this command directly is not supported.")
        )
    }
    
    public static func withSubcommands(_ commands: any ParsableCommand.Type...) -> Self.Type {
        configuration.subcommands = commands
        return Self.self
    }
}
