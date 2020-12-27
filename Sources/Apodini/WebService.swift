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


public extension WebService {
    /// This function is executed to start up an Apodini `WebService`
    static func main() {
        do {
            let app = try Self.prepare()
            defer {
                app.shutdown()
            }
            try app.run()
        } catch {
            print(error)
        }
    }
    
    /// The current version of the `WebService`
    var version: Version {
        Version()
    }
    
    /// An empty initializer used to create an Apodini `WebService`
    init() {
        self.init()
    }
}

internal extension WebService {
    static func prepare(testing: Bool = false) throws -> Vapor.Application {
        let environmentName = try Vapor.Environment.detect().name
        var env = testing
            ? .testing
            : Vapor.Environment(name: environmentName, arguments: ["vapor"])
        if !testing {
            try LoggingSystem.bootstrap(from: &env)
        }
        
        let app = Application(env)
        let webService = Self()
        
        webService.register(
            SharedSemanticModelBuilder(app, interfaceExporters: RESTInterfaceExporter.self, ProtobufferSemanticModelBuilder.self),
            GraphQLSemanticModelBuilder(app),
            GRPCSemanticModelBuilder(app),
            WebSocketSemanticModelBuilder(app)
        )
        
        webService.configuration.configure(app)
        
        return app
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
