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

/// A subcommand with a generic type that must conform to `Apodini.WebService`, used to start up the web service for
/// `MigratorConfiguration` tasks.
struct MigratorStartupSubcommand<Service: WebService>: ParsableCommand {
    /// Configuration of the subcommand with name `migrator`
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "migrator",
            abstract: "Starts up the web service",
            discussion: "Starts up an Apodini web service to perform the tasks of `MigratorConfiguration` and exits aftwards",
            version: "0.4.0"
        )
    }
    
    /// Runs this command
    func run() throws {
        try Service.start(mode: .startup)
    }
}
