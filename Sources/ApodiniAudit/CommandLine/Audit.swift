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

struct Audit<Service: WebService>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "audit",
            abstract: "Root subcommand of `ApodiniAudit`",
            discussion: "Audits the web service with regards to HTTP and REST best practiaces",
            version: "0.1.0",
            subcommands: [
                `default`,
            ],
            defaultSubcommand: `default`
        )
    }
    
    private static var `default`: ParsableCommand.Type {
        AuditRun.self
    }
}
