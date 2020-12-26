//
//  WebService.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Fluent
import FluentMongoDriver


/// Each Apodini program consists of a `WebService`component that is used to describe the Web API of the Web Service
public protocol WebService: Component, ConfigurationCollection {
    /// The current version of the `WebService`
    var version: Version { get }
    
    /// An empty initializer used to create an Apodini `WebService`
    init()
}


extension WebService {
    /// This function is executed to start up an Apodini `WebService`
    public static func main() throws {
        let app = Application()
        LoggingSystem.bootstrap(StreamLogHandler.standardError)

        main(app: app)
            
        defer {
            app.shutdown()
        }
        
        try app.run()
    }

    /// Creates a Vapor.Application and configures the LoggingSystem
    static func createApplication() throws -> Vapor.Application {
        #if DEBUG
        let arguments = [CommandLine.arguments.first ?? ".", "serve", "--env", "development", "--hostname", "0.0.0.0", "--port", "8080"]
        #else
        let arguments = [CommandLine.arguments.first ?? ".", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
        #endif

        var env = try Vapor.Environment.detect(arguments: arguments)
        try LoggingSystem.bootstrap(from: &env)
        return Application(env)
    }
    
    /// This function is provided to start up an Apodini `WebService`. The `app` parameter can be injected for testing purposes only. Use `WebService.main()` to startup an Apodini `WebService`.
    /// - Parameter app: The app instance that should be injected in the Apodini `WebService`
    static func main(app: Application) {
        let webService = Self()

        webService.configuration.configure(app)
        
        webService.register(
            SharedSemanticModelBuilder(app)
                .with(exporter: RESTInterfaceExporter.self)
                .with(exporter: WebSocketInterfaceExporter.self)
                .with(exporter: OpenAPIInterfaceExporter.self)
                .with(exporter: GRPCInterfaceExporter.self)
                .with(exporter: ProtobufferInterfaceExporter.self),
            GraphQLSemanticModelBuilder(app)
        )
    }
    
    
    /// The current version of the `WebService`
    public var version: Version {
        Version()
    }
}


extension WebService {
    func register(_ semanticModelBuilders: SemanticModelBuilder...) {
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: semanticModelBuilders)
        self.visit(visitor)
        visitor.finishParsing()
    }
    
    private func visit(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        visitor.addContext(PathComponentContextKey.self, value: [version], scope: .environment)
        Group {
            content
        }.accept(visitor)
    }
}
