//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Logging
import ArgumentParser

/// Each Apodini program consists of a `WebService`component that is used to describe the Web API of the Web Service
public protocol WebService: WebServiceMetadataNamespace, Component, ConfigurationCollection, ParsableCommand {
    typealias Metadata = AnyWebServiceMetadata
    
    /// The current version of the `WebService`
    var version: Version { get }
    
    /// An empty initializer used to create an Apodini `WebService`
    init()
}

// MARK: Metadata DSL
public extension WebService {
    /// WebService has an empty `AnyWebServiceMetadata` by default.
    var metadata: AnyWebServiceMetadata {
        Empty()
    }
}

extension WebService {
    /// Overrides  the `main()` method of `ParsableCommand`
    /// Store the values of wrapped properties in the `WebService` (eg. `@Environment`)  before parsing the CLI arguments and then restore the saved values after the parsing is finished
    public static func main(_ arguments: [String]? = nil) {     // swiftlint:disable:this discouraged_optional_collection
        let mirror = Mirror(reflecting: Self())
        var propertyStore: [String: ArgumentParserStoreable] = [:]
        
        // Backup of property wrapper values
        for child in mirror.children {
            if let property = child.value as? ArgumentParserStoreable {
                guard let label = child.label else {
                    fatalError("Label of the to be stored property couldn't be read!")
                }
                
                property.store(in: &propertyStore, keyedBy: label)
            }
        }
        
        // Parsing of Command Line Arguments and restoring the values of the property wrappers
        do {
            // Parse the CLI arguments
            var command = try parseAsRoot(arguments)
            
            let mirror = Mirror(reflecting: command)
            
            // Restore property wrapper values
            for child in mirror.children {
                if let property = child.value as? ArgumentParserStoreable {
                    guard let label = child.label else {
                        fatalError("Label of the to be stored property couldn't be read!")
                    }
                    
                    property.restore(from: propertyStore, keyedBy: label)
                }
            }
            
            // Start the webservice
            try command.run()
        } catch {
            exit(withError: error)
        }
    }
}

extension WebService {
    /// This function is executed to start up an Apodini `WebService`, called on an instantiated `WebService` containing the parsed CLI arguments
    public mutating func run() throws {
        try Self.start(mode: .run, webService: self)
    }
    /// The command configuration of the `ParsableCommand`
    public static var configuration: CommandConfiguration {
        CommandConfiguration(subcommands: Self().configuration._commands)
    }
    
    /// This function is executed to start up an Apodini `WebService`
    /// - Parameters:
    ///    - mode: The `WebServiceExecutionMode` in which the web service is executed in. Defaults to `.run`, meaning the web service is ran normally and able to handle requests.
    ///    - app: The instanciated `Application` that will be used to boot and start up the web service. Passes a default plain application, if nothing is specified.
    ///    - webService: The instanciated `WebService` by the Swift ArgumentParser containing CLI arguments.  If `WebService` isn't already instanciated by the Swift ArgumentParser, automatically create a default instance
    /// - Returns: The application on which the `WebService` is operating on
    @discardableResult
    public static func start(
        mode: WebServiceExecutionMode,
        app: Application = Application(),
        webService: Self = Self()
    ) throws -> Application {
        var webServiceCopy = webService
        /// Inject the `Application` instance to allow access to it directly in the `WebService` via the `@Environment` property wrapper
        Apodini.inject(app: app, to: &webServiceCopy)
        Apodini.activate(&webServiceCopy)
        
        webServiceCopy.start(app: app)
        
        switch mode {
        case .startup:
            return app
        case .boot:
            try app.boot()
            return app
        case .run:
            defer { app.shutdown() }
            try app.run()
            return app
        }
    }
    
    
    /// Start up a web service using the specified application. Does not boot or run the web service. Intended primarily for testing purposes.
    func start(app: Application) {
        /// Configure application and instanciate exporters
        self.configuration.configure(app)
        
        // If no specific address hostname is provided we bind to the default address to automatically and correctly bind in Docker containers.
        if app.http.address == nil {
            app.http.address = .hostname(HTTPConfiguration.Defaults.hostname, port: HTTPConfiguration.Defaults.port)
        }
        
        self.register(SemanticModelBuilder(app))
    }
    
    
    /// The current version of the `WebService`
    public var version: Version {
        Version()
    }
}


extension WebService {
    func register(_ modelBuilder: SemanticModelBuilder) {
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        self.visit(visitor)
        visitor.finishParsing()
    }
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        metadata.collectMetadata(visitor)

        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        visitor.addContext(PathComponentContextKey.self, value: [version], scope: .environment)

        if Content.self != Never.self {
            Group {
                content
            }.accept(visitor)
        }
    }
}


/// Specifies the mode in which the web service is executed in.
public enum WebServiceExecutionMode {
    /// Runs the configurations and the semantic model builder. It also boots the web service.
    /// Enters the runloop afterwards.
    case run
    /// Runs the configurations and the semantic model builder. It exits afterwards.
    case startup
    /// Runs the configurations and the semantic model builder and boots the web service.
    /// It exits afterwards.
    case boot
}
