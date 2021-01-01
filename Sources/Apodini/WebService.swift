//
//  WebService.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

@_implementationOnly import class Vapor.Application
@_implementationOnly import struct Vapor.Environment
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
    public static func main() {
        do {
            #if DEBUG
            var env = try Vapor.Environment.detect(arguments: [CommandLine.arguments.first ?? ".", "serve", "--env", "development", "--hostname", "0.0.0.0", "--port", "8080"])
            #else
            var env = try Vapor.Environment.detect(arguments: [CommandLine.arguments.first ?? ".", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"])
            #endif
            
            try LoggingSystem.bootstrap(from: &env)
            let app = Application(env)
            
            _main(app: app)
            
            defer {
                app.shutdown()
            }
            try app.run()
        } catch {
            print(error)
        }
    }
    
    /// This function is provided to start up an Apodini `WebService`. The `app` parameter can be injected for testing purposes only. Use `WebService.main()` to startup an Apodini `WebService`.
    /// - Parameter app: The app instance that should be injected in the Apodini `WebService`
    static func _main(app: Vapor.Application) {
        let webService = Self()

        webService.configuration.configure(app)
        
        webService.register(
            SharedSemanticModelBuilder(app)
                .with(exporter: RESTInterfaceExporter.self)
                .with(exporter: GRPCInterfaceExporter.self),
            GraphQLSemanticModelBuilder(app),
            WebSocketSemanticModelBuilder(app)
        )
    }
    
    
    /// The current version of the `WebService`
    public var version: Version {
        Version()
    }
    
    
    /// An empty initializer used to create an Apodini `WebService`
    public init() {
        self.init()
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
