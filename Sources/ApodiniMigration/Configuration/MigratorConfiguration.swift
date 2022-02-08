//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ArgumentParser
import ApodiniMigrationCommon

// MARK: - WebService
public extension WebService {
    /// A typealias for ``MigratorConfiguration``
    typealias Migrator = MigratorConfiguration<Self>
}

// MARK: - MigratorConfiguration
/// A configuration to handle migration tasks between two subsequent versions of an Apodini Web Service
/// - Note: Inside the `configuration` property of a ``WebService`` declaration, can be used via the typealias `Migrator`
public struct MigratorConfiguration<Service: WebService>: Configuration {
    let documentConfig: DocumentConfiguration?
    let migrationGuideConfig: MigrationGuideConfiguration?

    /// Initializer for a ``MigratorConfiguration`` instance. This configuration registers by default a `migrator` subcommand
    /// of the web service
    /// - Parameters:
    ///   - documentConfig: Configuration that determines how to handle the document of the current API version. If provided,
    ///   the configuration overrides the configuration obtained from `migrator document` subcommand
    ///   - migrationGuideConfig: Configuration of handling the migration guide. If provided, the configuration overrides,
    ///   the configuration obtained from `migrator compare` or `migrator read` subcommands
    /// - Note: Use empty initializer `Migrator()` in the `configuration` property of your Web Service,
    /// when you start it by means of one of `migrator` subsubcommands (`document`, `read` or `compare`)
    /// and provide its arguments via command-line.
    public init(
        documentConfig: DocumentConfiguration? = nil,
        migrationGuideConfig: MigrationGuideConfiguration? = nil
    ) {
        self.documentConfig = documentConfig
        self.migrationGuideConfig = migrationGuideConfig
    }

    /// Configures `app` by registering the ``InterfaceExporter`` that handles `ApodiniMigration` tasks
    /// - Parameters:
    ///   - app: Application instance which is used to register the configuration in Apodini
    public func configure(_ app: Application) {
        app.registerExporter(exporter: ApodiniMigratorInterfaceExporter(app, configuration: self))
    }

    /// Returns the `Migrator<Service>` type
    public var command: ParsableCommand.Type {
        Migrator<Service>.self
    }
}
