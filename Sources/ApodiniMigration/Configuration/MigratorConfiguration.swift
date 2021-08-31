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
import ArgumentParser

@_implementationOnly import ApodiniUtils
@_implementationOnly import Logging
@_implementationOnly import PathKit

/// Represents distinct cases of resource locations
public enum ResourceLocation {
    /// Errors thrown from `instance()`
    enum ResourceLocationError: Error {
        /// Not found error
        case notFound(message: String)
    }
    /// A file `path` (`absolute` or `relative`) pointing to the resource, e.g. `.file("./path/to/main.swift")`
    case file(_ path: String)
    /// A resource stored in `bundle` with the specified `fileName` and `format`,
    /// e.g. `.resource(.module, fileName: "resource", format: .yaml)`
    case resource(_ bundle: Bundle, fileName: String, format: FileFormat)
    
    var path: String? {
        switch self {
        case let .file(localPath):
            return localPath
        case let .resource(bundle, fileName, format):
            return bundle.path(forResource: fileName, ofType: format.rawValue)
        }
    }
}

/// A typealias for `OutputFormat`
public typealias FileFormat = OutputFormat

extension OutputFormat: ExpressibleByArgument {}

/// A configuration to handle migration tasks between two subsequent versions of an Apodini Web Service
/// - Note: Inside the `configuration` property of a `WebService` declaration, can be used via the typealias `Migrator`
public class MigratorConfiguration<Service: WebService>: Configuration {
    let documentConfig: DocumentConfiguration?
    let migrationGuideConfig: MigrationGuideConfiguration?
    let logger = Logger(label: "org.apodini.migrator")

    /// Initializer for a `MigratorConfiguration` instance. This configuration registers by default a `migrator` subcommand
    /// of the web service
    /// - Parameters:
    ///   - documentConfig: Configuration that determines how to handle the document of the current API version. If provided,
    ///   the configuration overrides the configuration obtained from `migrator document` subcommand
    ///   - migrationGuideConfig: Configuration of handling the migration guide. If provided, the configuration overrides,
    ///   the configuration obtained from `migrator compare` or `migrator read` subcommands
    public init(
        documentConfig: DocumentConfiguration? = nil,
        migrationGuideConfig: MigrationGuideConfiguration? = nil
    ) {
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

    /// Returns the `MigratorSubcommand` type
    public var command: ParsableCommand.Type {
        Migrator<Service>.self
    }
}

// MARK: - WebService
public extension WebService {
    /// A typealias for `MigratorConfiguration`
    typealias Migrator = MigratorConfiguration<Self>
}
