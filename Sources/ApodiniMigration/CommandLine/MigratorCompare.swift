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

// MARK: - MigratorCompare
struct MigratorCompare<Service: WebService>: MigratorParsableSubcommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "compare",
            abstract: "A parsable command for generating the migration guide",
            discussion: "Starts or runs the web service to compares the current API with a document of a previous version",
            version: "0.1.0"
        )
    }
    
    @Option(help: "A local `path` (`absolute` or `relative`) pointing to the document of the previous API version")
    var oldDocumentPath: String
    
    @OptionGroup
    var migrationGuideExport: MigrationGuideExportOptions
    
    @OptionGroup
    var documentExport: DocumentExportOptions
    
    @OptionGroup
    var webService: Service
    
    @Flag(help: "A flag that indicates whether the web service should run after executing the subcommand")
    var runWebService = false
    
    func run(app: Application) throws {
        app.storage.set(
            MigrationGuideConfigStorageKey.self,
            to: .init(exportOptions: migrationGuideExport, oldDocumentPath: oldDocumentPath)
        )
        app.storage.set(
            DocumentConfigStorageKey.self,
            to: .init(exportOptions: documentExport)
        )
        
        try start(app)
    }
}
