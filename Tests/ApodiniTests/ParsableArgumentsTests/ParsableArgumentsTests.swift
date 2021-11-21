//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import XCTApodini
import ApodiniUtils
@testable import ArgumentParser


class ParsableArgumentsTests: XCTApodiniTest {
    func getCommandError(_ error: Error) throws -> CommandError {
        try XCTUnwrap(error as? CommandError)
    }
    
    // When providing no or not all arguments, the parsing should fail
    func testFailedParsing() throws {
        // Throw an error when no arguments are provided
        XCTAssertThrowsError(try NoDefaultsTestWebService.parseAsRoot([]))
        // Throw an error when we provide only "localhost` for the `hostname` argument
        XCTAssertThrowsError(try NoDefaultsTestWebService.parseAsRoot(["localhost"]))
        // Throw an error when we provide only "80" for the `--port` option
        XCTAssertThrowsError(try NoDefaultsTestWebService.parseAsRoot(["--port", "80"]))
    }
    
    // Test if the web service is successfully parsed when the correct arguments are provided
    // Provided arguments:
    // hostname : "localhost"
    // --port   : "80"
    func testSuccessfulParsing() throws {
        let command = try NoDefaultsTestWebService.parse(["localhost", "--port", "80"])
        XCTAssertEqual(command.port, 80)
        XCTAssertEqual(command.hostname, "localhost")
    }
    
    // If there is a subcommand in a configuration and we call it directly without providing all web service
    // arguments, we expect it to fail with a noValue error because the `port` option of the web service is missing
    // Provided arguments:
    // hostname : "localhost"
    // --port   : <missing value>
    // test     : <commandName>
    // --test   : "50"
    func testFailedSubcommandIfInsufficientWSArguments() throws {
        do {
            _ = try NoDefaultsTestWebService.parse(["localhost", "test", "50"])
        } catch {
            let commandError = try getCommandError(error)
            switch commandError.parserError {
            case .noValue(forKey: let key):
                XCTAssertEqual(key.rawValue, "port")
            default:
                XCTFail("Wrong parser error found.")
            }
        }
    }
    
    // If there is a subcommand in a configuration and we call it directly providing the web service arguments,
    // we still expect it to fail with a noValue error because the `test` option of subcommand was not provided
    // hostname : "localhost"
    // --port   : "80"
    // test     : <commandName>
    // --test   : <missing value>
    func testFailedSubcommandWithInsufficientArguments() throws {
        do {
            _ = try TestCommand<NoDefaultsTestWebService>.parse(["localhost", "--port", "80", "test"])
        } catch {
            let commandError = try getCommandError(error)
            print(commandError)
            switch commandError.parserError {
            case .noValue(forKey: let key):
                XCTAssertEqual(key.rawValue, "test")
            default:
                XCTFail("Wrong parser error found.")
            }
        }
    }
    
    // If there is a subcommand in a configuration and we call it directly providing the web service arguments,
    // and we provided correct values for the subcommand's arguements/options, everything should work
    // Provided arguments:
    // hostname : "localhost"
    // --port   : "80"
    // test     : <commandName>
    // --test   : "50"
    // Note: Since we parse it as `TestCommand` we dont need to pass the `test` command explicitly to the commands.
    func testSubcommandSucceededWithArguments() throws {
        let testCommand = try TestCommand<NoDefaultsTestWebService>.parse([
            "localhost",
            "--port",
            "80",
            "--test",
            "50"
        ])
        XCTAssertEqual(testCommand.webServiceOptions.port, 80)
        XCTAssertEqual(testCommand.webServiceOptions.hostname, "localhost")
        XCTAssertEqual(testCommand.test, 50)
    }
    
// MARK: - Nested Commands Tests
    
    // If we have nested subcommands in the configuration as we do e.g. in the deployment providers
    // and we pass all web service arguments, but dont pass the options for the `super` nested arguments, it should fail.
    // Provided arguments:
    // hostname : "localhost"
    // --port   : "80"
    // nested-super : <commandName>
    // --object   : <missing value>
    func testNestedCommandsMissingSuperOption() throws {
        do {
            _ = try TestNestedCommand<NoDefaultsTestWebService>.parse([
                "localhost",
                "--port",
                "80",
                "nested-super",
                "nested-sub"
            ])
        } catch {
            let commandError = try getCommandError(error)
            print(commandError)
            switch commandError.parserError {
            case .noValue(forKey: let key):
                XCTAssertEqual(key.rawValue, "object")
            default:
                XCTFail("Wrong parser error found.")
            }
        }
    }
    
    // If we have nested subcommands in the configuration as we do e.g. in the deployment providers
    // and we pass all web service arguments, but dont pass the options for the `sub` nested arguments, it should fail.
    // Provided arguments:
    // hostname     : "localhost"
    // --port       : "80"
    // nested-super : <commandName>
    // --object     : "5"
    // nested-sub   : <commandName>
    // --name       : <missingValue>
    func testNestedCommandsMissingSubOption() throws {
        do {
            _ = try NestedCommand<NoDefaultsTestWebService>.parse([
                "localhost",
                "--port",
                "80",
                "nested-super",
                "5",
                "nested-sub"
            ])
        } catch {
            let commandError = try getCommandError(error)
            print(commandError)
            switch commandError.parserError {
            case .noValue(forKey: let key):
                XCTAssertEqual(key.rawValue, "name")
            default:
                XCTFail("Wrong parser error found.")
            }
        }
    }
    
    // If we have nested subcommands in the configuration as we do e.g. in the deployment providers
    // and we pass all web service arguments and the arguments for the `nested super command`,
    // the super command of the nested should be initialized correctly.
    // Provided arguments:
    // hostname     : "localhost"
    // --port       : "80"
    // nested-super : <commandName>
    // --object     : "50"
    func testNestedCommandSucceededWithoutSub() throws {
        let nestedSuperCommand = try TestNestedCommand<NoDefaultsTestWebService>.parse([
            "localhost",
            "--port",
            "80",
            "--object",
            "50"
        ])
        XCTAssertEqual(nestedSuperCommand.webServiceOptions.port, 80)
        XCTAssertEqual(nestedSuperCommand.webServiceOptions.hostname, "localhost")
        XCTAssertEqual(nestedSuperCommand.object, 50)
    }
    
    // If we have nested subcommands in the configuration as we do e.g. in the deployment providers
    // and we pass all web service arguments and the arguments for both nested commands, sub nested command
    // of the nested should be initialized correctly.
    // Provided arguments:
    // hostname     : "localhost"
    // --port       : "80"
    // nested-super : <commandName>
    // --object     : "50"
    // nested-sub : <commandName>
    // --name     : "apodini"
    func testNestedCommandSucceededWithSub() throws {
        let nestedSuperCommand = try NestedCommand<NoDefaultsTestWebService>.parse([
            "localhost",
            "--port",
            "80",
            "--name",
            "apodini"
        ])
        XCTAssertEqual(nestedSuperCommand.webServiceOptions.port, 80)
        XCTAssertEqual(nestedSuperCommand.webServiceOptions.hostname, "localhost")
        XCTAssertEqual(nestedSuperCommand.name, "apodini")
    }
}

// MARK: - Test Web Service
private struct NoDefaultsTestWebService: WebService {
    @Argument
    var hostname: String
    
    @Option
    var port: Int
    
    var content: some Component {
        Text("EmptyText")
    }
    
    var configuration: Configuration {
        HTTPConfiguration(bindAddress: .interface(hostname, port: port))
        TestSubcommandConfiguration<Self>()
        TestNestedSubcommandConfiguration<Self>()
    }
}

// MARK: - Configurations and Commands used for Testing
private struct TestSubcommandConfiguration<Service: WebService>: Configuration {
    func configure(_ app: Application) {
        print("👋")
    }
    
    var command: ParsableCommand.Type {
        TestCommand<Service>.self
    }
}

private struct TestCommand<Service: WebService>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "test")
    }
    
    @OptionGroup var webServiceOptions: Service
    @Option var test: Int
    
    func run() throws {
        print("Test: \(test)")
    }
}

private struct TestNestedSubcommandConfiguration<Service: WebService>: Configuration {
    @OptionGroup var webServiceOptions: Service
    
    var command: ParsableCommand.Type {
        TestNestedCommand<Service>.self
    }
    
    func configure(_ app: Application) {
        print("👋")
    }
}

private struct TestNestedCommand<Service: WebService>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "nested-super", subcommands: [NestedCommand<Service>.self])
    }
    
    @OptionGroup var webServiceOptions: Service
    @Option var object: Int
    
    func run() throws {
        print("Called from nested")
    }
}

private struct NestedCommand<Service: WebService>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "nested-sub")
    }
    
    @OptionGroup var webServiceOptions: Service
    @Option var name: String
    
    func run() throws {
        print("Greetings: \(name)")
    }
}
