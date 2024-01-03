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

struct SingleCommandConfiguration: Configuration {
    func configure(_ app: Application) {}
    
    var command: any ParsableCommand.Type {
        DummyParsableCommand.self
    }
}

struct MultipleCommandConfiguration: Configuration {
    func configure(_ app: Application) {}
    
    var command: any ParsableCommand.Type {
        DummyParsableCommandWithSubCommands.self
    }
}

struct DummyParsableCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "dummy")
    func run() throws {
        print("DummyParsableCommand")
    }
}

struct DummyParsableCommandWithSubCommands: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "mainCommand",
        subcommands: [DummySubCommand.self]
    )
    func run() throws {
        print("DummyParsableCommandWithSubCommands")
    }
}

struct DummySubCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "subCommand"
    )
    func run() throws {
        print("DummySubCommand")
    }
}
