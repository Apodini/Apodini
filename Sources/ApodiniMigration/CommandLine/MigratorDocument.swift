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

struct MigratorDocument<Service: WebService>: MigratorParsableSubcommand {
    @OptionGroup
    var export: DocumentExportOptions
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "document",
            abstract: "A parsable command for generating the API document of the initial web service version",
            discussion: "Runs the web service and exports the document of the current API",
            version: "0.1.0"
        )
    }
    
    func run(app: Application, mode: WebServiceExecutionMode) throws {
        app.storage.set(
            DocumentConfigStorageKey.self,
            to: .init(exportOptions: export)
        )
        try Service.start(mode: mode, app: app)
    }
}
