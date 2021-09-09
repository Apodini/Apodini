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

// MARK: - MigratorDocument
struct MigratorDocument<Service: WebService>: MigratorParsableSubcommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "document",
            abstract: "A parsable command for generating the API document of the initial web service version",
            discussion: "Starts or runs the web service to export the document of the current API",
            version: "0.1.0"
        )
    }
    
    @OptionGroup
    var export: DocumentExportOptions
    
    @OptionGroup
    var webService: Service
    
    @Flag(help: "A flag that indicates whether the web service should run after executing the subcommand")
    var runWebService = false
    
    func run(app: Application) throws {
        app.storage.set(
            DocumentConfigStorageKey.self,
            to: .init(exportOptions: export)
        )
        try start(app)
    }
}
