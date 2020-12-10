//
//  WebService.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

@_implementationOnly import Vapor
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
            let environmentName = try Environment.detect().name
            var env = Environment(name: environmentName, arguments: ["vapor"])
            try LoggingSystem.bootstrap(from: &env)
            let app = Application(env)

            let webService = Self()

            webService.register(
                SharedSemanticModelBuilder(app, interfaceExporters: RESTInterfaceExporter.self),
                GraphQLSemanticModelBuilder(app),
                GRPCSemanticModelBuilder(app),
                WebSocketSemanticModelBuilder(app)
            )

            webService.configuration.configure(app)

            defer {
                app.shutdown()
            }
            try app.run()
        } catch {
            print(error)
        }
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
    }
    
    private func visit(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        visitor.addContext(PathComponentContextKey.self, value: [version], scope: .environment)
        Group {
            content
        }.visit(visitor)
    }
}
