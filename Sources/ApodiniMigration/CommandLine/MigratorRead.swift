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

struct MigratorRead<Service: WebService>: ParsableCommand {
    @OptionGroup
    var migrationGuideExport: MigrationGuideExportOptions
    
    @OptionGroup
    var documentExport: DocumentExportOptions
    
    @Option(help: "A local `path` (`absolute` or `relative`) pointing to the migration guide")
    var migrationGuidePath: String
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "read",
            abstract: "A parsable command to export a local migration guide and the API document of the current version",
            discussion: "Runs an Apodini web service and exports the migration guide",
            version: "0.1.0"
        )
    }
    
    func run() throws {
        let app = Application()
        app.storage.set(
            MigrationGuideConfigStorageKey.self,
            to: .init(exportOptions: migrationGuideExport, migrationGuidePath: migrationGuidePath)
        )
        app.storage.set(
            DocumentConfigStorageKey.self,
            to: .init(exportOptions: documentExport)
        )
        try Service.start(mode: .run, app: app)
    }
}
