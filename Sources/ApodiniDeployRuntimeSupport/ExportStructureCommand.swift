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
        public var identifier: String = "de.tum.in.ase.apodini.deploy"
        
        public init() {}
    }
    
    public static var configuration = CommandConfiguration(
        commandName: "export-ws-structure",
        abstract: "Export web service structure",
        discussion: "Exports an Apodini web service structure",
        version: "0.3.0"
    )
    
    public func run() throws {
        ExportStructureCommand.helpMessage(columns: nil)
        ExportStructureCommand.exit(withError:
            ApodiniDeployRuntimeSupportError(message: "Calling this command directly is not supported.")
        )
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
        discussion: "Starts up a node a deployment system",
        version: "0.3.0"
    )

    public init() {}
    
    public func run() throws {
        StartupCommand.helpMessage(columns: nil)
        StartupCommand.exit(withError:
            ApodiniDeployRuntimeSupportError(message: "Calling this command directly is not supported.")
        )
    }
    
    public static func withSubcommands(_ commands: [ParsableCommand.Type]) -> StartupCommand.Type {
        configuration.subcommands = commands
        return StartupCommand.self
    }
}

extension WebService {
    /// An instance start function that can be used by the deployment related start and export structure commands,
    /// since they all have access to an instanciated object of the `WebService`. Leave it here until a general revamp of the start function.
    public func start(mode: WebServiceExecutionMode, app: Application) throws {
        try Self.start(mode: mode, app: app, webService: self)
    }
}
