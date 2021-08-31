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
    @Option(help: "A local `path` (`absolute` or `relative`) pointing to the document of the previous API version")
    var oldDocumentPath: String
    
    @OptionGroup
    var export: ExportOptions
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "compare",
            abstract: "A parsable command for generating the migration guide",
            discussion: "Compares the current API with a document of a previous version, and then runs the web service",
            version: "0.1.0"
        )
    }
    
    func run() throws {
        try run(setting: MigrationGuideConfigStorageKey.self, to: MigrationGuideConfiguration(exportOptions: export, oldDocumentPath: oldDocumentPath))
    }
}
