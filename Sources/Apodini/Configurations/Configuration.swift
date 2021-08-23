//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import ArgumentParser
/// `Configuration`s are used to register services to Apodini.
/// Each `Configuration` handles different kinds of services.
public protocol Configuration {
    /// A method that handles the configuration of a service which is called by the `main` function.
    ///
    /// - Parameter
    ///    - app: The `Vapor.Application` which is used to register the configuration in Apodini
    func configure(_ app: Application)
    
    /// A default CLI command that can be defined by the configuration.
    /// This command is automatically integrated into the Apodini CLI,
    /// if the `CommandConfiguration` has not been overridden.
    var command: ParsableCommand.Type { get }
    
    // swiftlint:disable identifier_name
    /// *For internal use only:* An array of the `command` of the configuration.
    /// Used to allow iteration over the commands of a `ConfigurationBuilder`.
    var _commands: [ParsableCommand.Type] { get }
}

/// This protocol is used by the `WebService` to declare `Configuration`s in an instance
public protocol ConfigurationCollection {
    /// This stored property defines the `Configuration`s of the `WebService`
    @ConfigurationBuilder var configuration: Configuration { get }
}

extension Configuration {
    // swiftlint:disable identifier_name
    /// *For internal use only:* An array of the `command` of the configuration.
    /// Used to allow iteration over the commands of a `ConfigurationBuilder`.
    public var _commands: [ParsableCommand.Type] {
        [self.command]
    }
    
    /// Default implementation of the cli command
    public var command: ParsableCommand.Type {
        EmptyCommand.self
    }
}

extension ConfigurationCollection {
    /// The default configuration is an `EmptyConfiguration`
    @ConfigurationBuilder public var configuration: Configuration {
        EmptyConfiguration()
    }
}


public struct EmptyConfiguration: Configuration {
    public func configure(_ app: Application) { }
    
    public init() { }
}

public struct EmptyCommand: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "")
    }
    
    public init() {}
}


extension Array: Configuration where Element == Configuration {
    public func configure(_ app: Application) {
        forEach {
            $0.configure(app)
        }
    }
    // swiftlint:disable identifier_name
    public var _commands: [ParsableCommand.Type] {
        compactMap {
            $0.command
        }
    }
}
