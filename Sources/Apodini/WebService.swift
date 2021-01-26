//
//  WebService.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//
import Logging

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
        try main(waitForCompletion: true)
    }

    /// This function is executed to start up an Apodini `WebService`
    static func main(waitForCompletion: Bool) throws {
        let app = Application()
        LoggingSystem.bootstrap(StreamLogHandler.standardError)

        main(app: app)

        guard waitForCompletion else {
            return try app.boot()
        }

        defer {
            app.shutdown()
        }

        try app.run()
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
        
        // Adds the created application instance to `EnvironmentValues`.
        // Can be used `@Environment` to access properties.
        EnvironmentValues.shared.values[ObjectIdentifier(Application.Type.self)] = app

        app.vapor.app.routes.defaultMaxBodySize = "1mb"
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
