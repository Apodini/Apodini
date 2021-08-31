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

struct MigratorRead<Service: WebService>: MigratorParsableSubcommand {
    @OptionGroup
    var export: ExportOptions
    
    @Option(help: "A local `path` (`absolute` or `relative`) pointing to the migration guide")
    var migrationGuidePath: String
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "read",
            abstract: "A parsable command to export the migration guide",
            discussion: "Runs an Apodini web service and exports the migration guide",
            version: "0.1.0"
        )
    }
    
    func run() throws {
        try run(setting: MigrationGuideConfigStorageKey.self, to: MigrationGuideConfiguration(exportOptions: export, migrationGuidePath: migrationGuidePath))
    }
}
