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
import ApodiniMigrator

struct MigratorCompare<Service: WebService>: MigratorParsableSubcommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "compare",
            abstract: "A parsable command for generating the migration guide",
            discussion: "Compares the current API with a document of a previous version, and then runs the web service",
            version: "0.1.0"
        )
    }
    
    @Option(help: "A local `path` (`absolute` or `relative`) pointing to the document of the previous API version")
    var oldDocumentPath: String
    
    @OptionGroup
    var migrationGuideExport: MigrationGuideExportOptions
    
    @OptionGroup
    var documentExport: DocumentExportOptions
    
    func run(app: Application, mode: WebServiceExecutionMode) throws {
        app.storage.set(
            MigrationGuideConfigStorageKey.self,
            to: .init(exportOptions: migrationGuideExport, oldDocumentPath: oldDocumentPath)
        )
        app.storage.set(
            DocumentConfigStorageKey.self,
            to: .init(exportOptions: documentExport)
        )
        try Service.start(mode: mode, app: app)
    }
}
