import Foundation
import ArgumentParser

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
    
    public static var configuration: CommandConfiguration = CommandConfiguration(
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
    
    public static func commands(_ commands: [ParsableCommand.Type]) -> ExportStructureCommand.Type {
        configuration.subcommands = commands
        return ExportStructureCommand.self
    }
    
    public init() {}
}
