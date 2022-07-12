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

// MARK: - AuditRun
struct AuditRunCommand<Service: WebService>: AuditParsableSubcommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "run",
            abstract: "",
            discussion: "",
            version: "0.1.0"
        )
    }
    
    @OptionGroup
    var webService: Service
    
    func run(app: Application) throws {
        try start(app)
    }
}
