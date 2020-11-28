//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Vapor

/// Each Apodini program conists of a `WebService`component that is used to describe the Web API of the Web Service
public protocol WebService: Component {
    /// The currennt version of the `WebService`
    var version: Version { get }
    
    /// An empty initializer used to create an Apodini `WebService`
    init()
}


extension WebService {
    /// This function is exectured to start up an Apodini `WebService`
    public static func main() {
        do {
            var env = try Environment.detect()
            try LoggingSystem.bootstrap(from: &env)
            let app = Application(env)
            
            let webService = Self()
            
            webService.register(
                RESTSemanticModelBuilder(app),
                GraphQLSemanticModelBuilder(app),
                GRPCSemanticModelBuilder(app),
                WebSocketSemanticModelBuilder(app),
                OpenAPISemanticModelBuilder(app)
            )
            
            defer {
                app.shutdown()
            }
            try app.run()
        } catch {
            print(error)
        }
    }
    
    
    /// The currennt version of the `WebService`
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
        let visitor = SynaxTreeVisitor(semanticModelBuilders: semanticModelBuilders)
        self.visit(visitor)
    }
    
    private func visit(_ visitor: SynaxTreeVisitor) {
        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        visitor.addContext(PathComponentContextKey.self, value: [version], scope: .environment)
        Group {
            content
        }.visit(visitor)
    }
}
