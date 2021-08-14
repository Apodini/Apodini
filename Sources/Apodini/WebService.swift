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
    /// This function is executed to start up an Apodini `WebService`, called by Swift ArgumentParser on instantiated `WebService` containing CLI arguments
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
        mode: WebServiceExecutionMode,// = .run,
        app: Application = Application(),
        webService: Self = Self()
    ) throws -> Application {
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        
        webService.start(app: app)
        
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
    /// Boots and starts the web service as one would normally do. This is default.
    case run
    /// This only starts the web service. This means it runs the configurations and iterates through the exporters.
    /// This does not boot the web service. It exists afterwards.
    case startup
    /// This starts and boots the web service. It runs configurations and the semantic model builder. It also boots the web service.
    /// This means that the corresponding life cycle methods are called and the `boot` method of `Vapor.App` is executed.
    /// The web service exists afterwards
    case boot
}
