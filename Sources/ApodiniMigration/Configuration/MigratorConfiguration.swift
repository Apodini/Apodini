//
//  File.swift
//  
//
//  Created by Eldi Cano on 07.08.21.
//

import Foundation
import Apodini
import ApodiniMigratorShared
@_implementationOnly import ApodiniUtils

/// Represents distinct cases of export paths
public enum ExportPath {
    /// Exports a content in a file at `directoryPath`
    case file(_ directoryPath: String)
    /// Serves a content at a route of the web service at `path`
    case endpoint(_ path: String)
}

/// A configuration object for handling the API specification document
public struct DocumentConfiguration {
    let exportPath: ExportPath
    let outputFormat: OutputFormat
    
    /// A convenient static function for initializing a `DocumentConfiguration`
    /// - Parameters:
    ///   - path: Export path for the document to be generated
    ///   - format: Output format of the document to be generated, either `json` or `yaml`
    /// - Returns: a `DocumentConfiguration` instance
    public static func export(at path: ExportPath, as format: OutputFormat) -> DocumentConfiguration {
        .init(exportPath: path, outputFormat: format)
    }
}

/// A configuration object with distinct strategies how to handle the migration guide
public enum MigrationGuideConfiguration {
    /// `none` strategy, to be used for the initial API version
    case none
    /// Compares an *old document* at `documentPath`, and exports the generated migration guide at `exportAt` as `asFormat`
    case compare(documentPath: String, exportAt: ExportPath, asFormat: OutputFormat)
    /// Reads the migration guide from `fromPath` and exports it at `exportAt` as `asFormat`
    case read(fromPath: String, exportAt: ExportPath, asFormat: OutputFormat)
}

/// A configuration to handle migration tasks between two subsequent versions of an Apodini Web Service
public class MigratorConfiguration: Configuration {
    let documentConfig: DocumentConfiguration
    let migrationGuideConfig: MigrationGuideConfiguration
    
    /// Initializer for a `MigratorConfiguration` instance
    /// - Parameters:
    ///   - documentConfig: Configuration that determines how to handle the document of the current API version
    ///   - migrationGuideConfig: Configuration of handling the migration guide
    public init(
        documentConfig: DocumentConfiguration,
        migrationGuideConfig: MigrationGuideConfiguration = .none
    ) {
        self.documentConfig = documentConfig
        self.migrationGuideConfig = migrationGuideConfig
        
        #if Xcode
        runShellCommand(.killPort(8080))
        #endif
    }
    
    public func configure(_ app: Application) {
        app.registerExporter(exporter: ApodiniMigratorInterfaceExporter(app, configuration: self))
    }
}
