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

/// Root subcomand of `ApodiniMigrator`
struct Migrator<Service: WebService>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "migrator",
            abstract: "Root subcommand of `ApodiniMigrator`",
            discussion: "Runs an Apodini web service based on the configurations of a subsubcommand",
            version: "0.1.0",
            subcommands: [
                `default`,
                MigratorRead<Service>.self,
                MigratorCompare<Service>.self
            ],
            defaultSubcommand: `default`
        )
    }
    
    static var `default`: ParsableCommand.Type {
        MigratorDocument<Service>.self
    }
}
