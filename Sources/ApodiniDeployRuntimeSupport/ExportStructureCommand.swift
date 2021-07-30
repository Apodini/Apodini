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
import Runtime

/// A CLI command responsible for exporting the structure of the web service.
/// The export can be configured by providing options and arguments.
/// The default implementation of this command exports the structure without any constraints.
/// A deployment provider may define a subcommand to this to account for custom options.
/// **Note**: Should not be called by the user directly
public struct ExportStructureCommand: ParsableCommand {
    /// Often used options that can be imported into a subcommand.
    public struct ExportOptions: ParsableArguments {
        @Argument(help: "The location of the json file")
        public var filePath: String = "service-structure.json"
        
        @Option(help: "The identifier of the deployment provider")
        public var identifier: String = "de.lukaskollmer.ApodiniDeploymentProvider.Localhost"
        
        public init() {}
    }
    
    public static var configuration = CommandConfiguration(
        commandName: "export-ws-structure",
        abstract: "Export web service structure",
        discussion: """
                    Exports an Apodini web service structure
                    """,
        version: "0.0.1",
        subcommands: []
    )
    
    public func run() throws {
        print("Export ws structure")
    }
    
    public static func withSubcommands(_ commands: [ParsableCommand.Type]) -> ExportStructureCommand.Type {
        configuration.subcommands = commands
        return ExportStructureCommand.self
    }
    
    public init() {}
}

public struct StartupCommand: ParsableCommand {
    public struct CommonOptions: ParsableArguments {
        @Argument(help: "The location of the json containing the system structure")
        public var fileUrl: String
        
        @Option(help: "The identifier of the deployment node")
        public var nodeId: String
        
        public init() {}
    }
    
    public static var configuration = CommandConfiguration(
        commandName: "startup",
        abstract: "Startup command for a node of a deployment system",
        discussion: """
                    Starts up a node a deployment system
                    """,
        version: "0.0.1",
        subcommands: []
    )

    public init() {}
    
    public func run() throws {
        fatalError(
            "Error: Should not be called directly. Use the startup command in the DeploymentProviderRuntime protocol."
        )
    }
    
    public static func withSubcommands(_ commands: [ParsableCommand.Type]) -> StartupCommand.Type {
        configuration.subcommands = commands
        return StartupCommand.self
    }
}
