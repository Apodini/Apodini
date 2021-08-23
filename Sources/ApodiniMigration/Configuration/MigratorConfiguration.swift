//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniMigratorShared
@_implementationOnly import ApodiniUtils
import Logging
import ArgumentParser
@_implementationOnly import PathKit

/// Represents distinct cases of export paths
public enum ExportPath {
    /// ExportPath at a local directory in `path`
    case directory(_ path: String)
    /// Serves a content at a route of the web service at `path`
    case endpoint(_ path: String)
}

/// Represents distinct cases of resource locations
public enum ResourceLocation {
    /// Errors thrown from `instance()`
    enum ResourceLocationError: Error {
        /// Not found error
        case notFound(message: String)
    }
    /// A local `path` (`absolute` or `relative`) pointing to the resource, e.g. `.local("./path/to/main.swift")`
    case local(_ path: String)
    /// A resource stored in `bundle` with the specified `fileName` and `format`,
    /// e.g. `.resource(.module, fileName: "resource", format: .yaml)`
    case resource(_ bundle: Bundle, fileName: String, format: FileFormat)
    
    /// Returns the decodable instance at `self`
    /// - Throws: If resource not found in the bundle or if the decoding fails
    func instance<D: Decodable>() throws -> D {
        let path: Path
        switch self {
        case let .local(localPath):
            path = .init(localPath)
        case let .resource(bundle, fileName, format):
            guard let url = bundle.url(forResource: fileName, withExtension: format.rawValue) else {
                throw ResourceLocationError.notFound(message: "Resource \(fileName).\(format.rawValue) not found in the bundle")
            }
            path = .init(url.path)
        }
        return try D.decode(from: path)
    }
}

/// A typealias for `OutputFormat`
public typealias FileFormat = OutputFormat

/// A configuration object for handling the API specification document
public struct DocumentConfiguration {
    let exportPath: ExportPath
    let format: FileFormat
    
    /// A convenient static function for initializing a `DocumentConfiguration`
    /// - Parameters:
    ///   - path: Export path for the document to be generated
    ///   - format: Format of the document to be generated, either `json` or `yaml`
    /// - Returns: a `DocumentConfiguration` instance
    public static func export(at path: ExportPath, as format: FileFormat) -> DocumentConfiguration {
        .init(exportPath: path, format: format)
    }
}

/// A configuration object with distinct strategies how to handle the migration guide
public enum MigrationGuideConfiguration {
    /// `none` strategy, to be used for the initial API version
    case none
    /// Compares the current API version with an *old document* at `documentLocation`,
    /// and exports the generated migration guide at `exportAt` `as` the specified file format
    case compare(_ documentLocation: ResourceLocation, exportAt: ExportPath, as: FileFormat)
    /// Reads the migration guide from `migrationGuideLocation` and exports it at `exportAt` `as` the specified file format
    case read(_ migrationGuideLocation: ResourceLocation, exportAt: ExportPath, as: FileFormat)
}

/// A typealias for `MigratorConfiguration`
public typealias Migrator = MigratorConfiguration

/// A configuration to handle migration tasks between two subsequent versions of an Apodini Web Service
public class MigratorConfiguration: Configuration {
    let documentConfig: DocumentConfiguration
    let migrationGuideConfig: MigrationGuideConfiguration
    let subcommandType: ApodiniMigratorParsableCommand.Type?
    let logger = Logger(label: "org.apodini.migrator")
    
    /// Initializer for a `MigratorConfiguration` instance
    /// - Parameters:
    ///   - documentConfig: Configuration that determines how to handle the document of the current API version
    ///   - migrationGuideConfig: Configuration of handling the migration guide. Defaults to `.none`
    ///   - subcommand: An optional command-line subcommand to perform `MigratorConfiguration` tasks. Defaults to `nil`
    public init(
        documentConfig: DocumentConfiguration,
        migrationGuideConfig: MigrationGuideConfiguration = .none,
        using subcommandType: ApodiniMigratorParsableCommand.Type? = nil
    ) {
        self.subcommandType = subcommandType
        self.documentConfig = documentConfig
        self.migrationGuideConfig = migrationGuideConfig
        
        #if Xcode
        runShellCommand(.killPort(8080))
        #endif
    }
    
    /// Configures `app` by registering the `InterfaceExporter` that handles migration tasks
    /// - Parameters:
    ///   - app: Application instance which is used to register the configuration in Apodini
    public func configure(_ app: Application) {
        app.registerExporter(exporter: ApodiniMigratorInterfaceExporter(app, configuration: self))
    }
    
    /// Returns the `subcommandType` if specified, otherwise `EmptyCommand.self`
    public var command: ParsableCommand.Type {
        subcommandType ?? EmptyCommand.self
    }
}
