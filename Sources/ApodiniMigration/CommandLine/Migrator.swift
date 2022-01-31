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

// MARK: - Migrator
/// Root subcomand of `ApodiniMigrator`
struct Migrator<Service: WebService>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "migrator",
            abstract: "Root subcommand of `ApodiniMigrator`",
            discussion: "Starts or runs an Apodini web service based on the configurations of a subsubcommand",
            version: "0.1.0",
            subcommands: [
                `default`,
                MigratorRead<Service>.self,
                MigratorCompare<Service>.self
            ],
            defaultSubcommand: `default`
        )
    }
    
    private static var `default`: ParsableCommand.Type {
        MigratorDocument<Service>.self
    }
}

// MARK: - MigratorParsableSubcommand
protocol MigratorParsableSubcommand: ParsableCommand {
    associatedtype Service: WebService
    
    var webService: Service { get }
    var runWebService: Bool { get }
    
    func run(app: Application) throws
}

extension MigratorParsableSubcommand {
    func run() throws {
        try run(app: Application())
    }
    
    func start(_ app: Application) throws {
        try Service.start(mode: runWebService ? .run : .boot, app: app, webService: webService)
    }
}
