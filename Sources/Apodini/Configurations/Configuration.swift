//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ArgumentParser
import ApodiniUtils


/// `Configuration`s are used to register services to Apodini.
/// Each `Configuration` handles different kinds of services.
public protocol Configuration {
    /// A method that handles the configuration of a service which is called by the `main` function.
    ///
    /// - Parameter
    ///    - app: The `Apodini.Application` which is used to register the configuration in Apodini
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
        forEach { $0.configure(app) }
    }
    // swiftlint:disable identifier_name
    public var _commands: [ParsableCommand.Type] {
        compactMap { $0.command }
    }
}


// MARK: Conditional Configurations

/// The `ConfigurationCondition` type can be used to make `Configuration`s conditional,
/// i.e. have them take effect only under certain circumstances.
public struct ConfigurationCondition {
    private let predicate: (Application) -> Bool
    
    init(_ predicate: @escaping (Application) -> Bool) {
        self.predicate = predicate
    }
    
    init(_ predicate: @escaping () -> Bool) {
        self.predicate = { _ in predicate() }
    }
    
    func evaluate(against app: Application) -> Bool {
        predicate(app)
    }
}


extension ConfigurationCondition {
    /// A condition which checks whether the web service has HTTPS enabled.
    public static let isHTTPSEnabled = ConfigurationCondition { app in app.httpConfiguration.tlsConfiguration != nil }
    
    /// A condition which checks for the current operating systerm
    public static func isOS(_ os: OperatingSystem) -> ConfigurationCondition {
        ConfigurationCondition { os == .current }
    }
    
    /// A condition which checks for the current architecture
    public static func isArch(_ arch: Architecture) -> ConfigurationCondition {
        ConfigurationCondition { arch == .current }
    }
    
    /// A condition which evaluates to true only if the program was compiled as a debug build
    public static let isDebugBuild = ConfigurationCondition { ApodiniUtils.isDebugBuild() }
    
    /// A condition which evaluates to true only if the program was compiled as a release build
    public static let isReleaseBuild = !isDebugBuild
}


extension ConfigurationCondition {
    /// Creates a condition by combining two other conditions with a logical NOT operation
    public static prefix func ! (condition: Self) -> ConfigurationCondition {
        ConfigurationCondition { !condition.evaluate(against: $0) }
    }
    
    /// Creates a condition by combining two other conditions with a logical AND operation
    public static func && (lhs: Self, rhs: Self) -> ConfigurationCondition {
        ConfigurationCondition { app in
            lhs.evaluate(against: app) && rhs.evaluate(against: app)
        }
    }

    /// Creates a condition by combining two other conditions with a logical OR operation
    public static func || (lhs: Self, rhs: Self) -> ConfigurationCondition {
        ConfigurationCondition { app in
            lhs.evaluate(against: app) || rhs.evaluate(against: app)
        }
    }
}


public struct ConditionalConfiguration: Configuration {
    /// The condition which needs to evaluate to true in order for this configuration to take effect
    let condition: ConfigurationCondition
    /// The underlying configuration
    let configuration: Configuration
    
    public func configure(_ app: Application) {
        if condition.evaluate(against: app) {
            configuration.configure(app)
        }
    }
    
    public var command: ParsableCommand.Type {
        configuration.command
    }
    
    public var _commands: [ParsableCommand.Type] {
        configuration._commands
    }
}


extension Configuration {
    /// Causes the configuration to only take effect if the specified condition evaluates to true
    public func enable(if condition: ConfigurationCondition) -> Configuration {
        ConditionalConfiguration(condition: condition, configuration: self)
    }
    
    /// Causes the configuration to only take effect if the specified condition evaluates to true
    public func enable(if condition: @escaping () -> Bool) -> Configuration {
        ConditionalConfiguration(condition: ConfigurationCondition(condition), configuration: self)
    }
    
    /// Causes the configuration to be skipped if the specified condition evaluates to true
    public func skip(if condition: ConfigurationCondition) -> Configuration {
        ConditionalConfiguration(condition: !condition, configuration: self)
    }
    
    /// Causes the configuration to be skipped if the specified condition evaluates to true
    public func skip(if condition: @escaping () -> Bool) -> Configuration {
        ConditionalConfiguration(condition: !ConfigurationCondition(condition), configuration: self)
    }
}
