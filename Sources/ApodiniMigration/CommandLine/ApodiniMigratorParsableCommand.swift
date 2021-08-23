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

/// A protocol for subcommands to be used in `MigratorConfiguration`
public protocol ApodiniMigratorParsableCommand: ParsableCommand {}

/// A subcommand with a generic type that must conform to `Apodini.WebService`, used to start up the web service for
/// `MigratorConfiguration` tasks.
///  - Note: Inside the `configuration` property of a `WebService` declaration, can be used via the typealias `MigratorSubcommand`
public struct ApodiniMigratorStartupSubcommand<Service: WebService>: ApodiniMigratorParsableCommand {
    /// Configuration of the subcommand with name `migrator`
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "migrator",
            abstract: "Starts up the web service",
            discussion: "Starts up an Apodini web service to perform the tasks of `MigratorConfiguration` and exits aftwards",
            version: "0.4.0"
        )
    }
    
    /// Runs this command
    public func run() throws {
        try Service.start(mode: .startup)
    }
    
    /// Creates a new `MigratorSubcommand` instance
    public init() {}
}

// MARK: - WebService
public extension WebService {
    /// A typealias for `ApodiniMigratorStartupSubcommand`
    typealias MigratorSubcommand = ApodiniMigratorStartupSubcommand<Self>
}
