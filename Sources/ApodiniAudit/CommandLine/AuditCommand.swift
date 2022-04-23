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

// MARK: - Audit

// Taken from `Migrator`

struct AuditCommand<Service: WebService>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "audit",
            abstract: "Root subcommand of `ApodiniAudit`",
            discussion: "Audits the web service with regards to HTTP and REST best practices",
            version: "0.1.0",
            subcommands: [
                runCommand,
                AuditSetupNLTKCommand<Service>.self
            ],
            defaultSubcommand: runCommand
        )
    }
    
    private static var runCommand: ParsableCommand.Type {
        AuditRunCommand<Service>.self
    }
}

// MARK: - AuditParsableSubcommand
protocol AuditParsableSubcommand: ParsableCommand {
    associatedtype Service: WebService
    
    var webService: Service { get }
    
    func run(app: Application) throws
}

extension AuditParsableSubcommand {
    func start(_ app: Application) throws {
        // Only builds the semantic model to run the InterfaceExporters, does not run the web service
        try Service.start(mode: .startup, app: app, webService: webService)
    }
}
