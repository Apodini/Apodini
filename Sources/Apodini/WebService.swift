//
//  WebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Foundation
import Logging
import ArgumentParser
@_implementationOnly import Runtime

/// Each Apodini program consists of a `WebService`component that is used to describe the Web API of the Web Service
public protocol WebService: WebServiceMetadataNamespace, Component, ConfigurationCollection, ParsableCommand {
    typealias Metadata = AnyWebServiceMetadata
    
    static var subcommands: [ParsableCommand.Type] { get }
    
    /// The current version of the `WebService`
    var version: Version { get }
    
    /// An empty initializer used to create an Apodini `WebService`
    init()
}

// MARK: WebService + Metadata DSL
public extension WebService {
    /// WebService has an empty `AnyWebServiceMetadata` by default.
    var metadata: AnyWebServiceMetadata {
        Empty()
    }
}


// MARK: WebService + Subcommands
public extension WebService {
    static var subcommands: [ParsableCommand.Type] {
        []
    }
}


private struct Start: ParsableCommand {
    static var configuration: CommandConfiguration = CommandConfiguration()
}


// MARK: WebService + Main
extension WebService {
    public static func main() {
        main(nil)
    }
    
    public static func main(_ arguments: [String]?) {
        // If we would be able to create an instance of the web service we would even get the subcommands from the Configuration
        // https://github.com/wickwirew/Runtime/pull/91 needs to be solved first.
        let webService = try? createInstance(of: Self.self) as? Self.Type
        var subcommands = webService?.configuration.subcommands ?? []
        // A workaround for the poblem above would be to have a static subcommands property
        subcommands.append(contentsOf: Self.subcommands)
        
        // We will definitiely add the Web Service instance itself to the list of subcommands
        subcommands.append(Self.self)
        
        // This seems to work independent of the way we get the subcommends above:
        var configuration = Self.configuration
        configuration.subcommands.append(contentsOf: subcommands)
        configuration.defaultSubcommand = Self.self
        
        Start.configuration = configuration
        do {
            var command = try Start.parseAsRoot(arguments)
            try command.validate()
            try command.run()
        } catch {
            Self.exit(withError: error)
        }
    }
    
    /**
     This function is executed to start up an Apodini `WebService`
     - Parameters:
         - waitForCompletion: Indicates whether the `Application` is launched or just booted. Defaults to true, meaning the `Application` is run
         - webService: The instanciated `WebService` by the Swift ArgumentParser containing CLI arguments.  If `WebService` isn't already instanciated by the Swift ArgumentParser, automatically create a default instance
     - Returns: The application on which the `WebService` is operating on
     */
    @discardableResult
    static func start(waitForCompletion: Bool = true, webService: Self = Self()) throws -> Application {
        let app = Application()
        LoggingSystem.bootstrap(StreamLogHandler.standardError)

        start(app: app, webService: webService)
        
        guard waitForCompletion else {
            try app.boot()
            return app
        }

        defer {
            app.shutdown()
        }

        try app.run()
        return app
    }
    

    /**
     This function is provided to start up an Apodini `WebService`. The `app` parameter can be injected for testing purposes only. Use `WebService.start()` to startup an Apodini `WebService`.
     - Parameters:
         - app: The app instance that should be injected in the Apodini `WebService`
         - webService: The instanciated `WebService` by the Swift ArgumentParser containing CLI arguments.  If `WebService` isn't already instanciated by the Swift ArgumentParser, automatically create a default instance
     */
    static func start(app: Application, webService: Self = Self()) {
        /// Configure application and instanciate exporters
        webService.configuration.configure(app)
        
        // If no specific address hostname is provided we bind to the default address to automatically and correctly bind in Docker containers.
        if app.http.address == nil {
            app.http.address = .hostname(HTTPConfiguration.Defaults.hostname, port: HTTPConfiguration.Defaults.port)
        }
        
        webService.register(
            SemanticModelBuilder(app)
        )
    }
    
    
    /// The current version of the `WebService`
    public var version: Version {
        Version()
    }
    
    
    /// This function is executed to start up an Apodini `WebService`, called by Swift ArgumentParser on instanciated `WebService` containing CLI arguments
    public mutating func run() throws {
        try Self.start(webService: self)
    }
    
    func register(_ modelBuilder: SemanticModelBuilder) {
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        self.visit(visitor)
        visitor.finishParsing()
    }
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)

        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        visitor.addContext(PathComponentContextKey.self, value: [version], scope: .environment)

        if Content.self != Never.self {
            Group {
                content
            }.accept(visitor)
        }
    }
}
