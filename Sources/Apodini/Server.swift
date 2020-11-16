//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Vapor


public protocol Server: ComponentCollection {
    var version: Version { get }
    
    init()
}


extension Server {
    public static func main() {
        do {
            var env = try Environment.detect()
            try LoggingSystem.bootstrap(from: &env)
            let app = Application(env)
            
            let server = Self()
            
            server.register(
                RESTSemanticModelBuilder(app),
                GraphQLSemanticModelBuilder(app),
                GRPCSemanticModelBuilder(app),
                WebSocketSemanticModelBuilder(app)
            )
            
            // APNS Configuration
//            app.apns.configuration = try .init(
//                authenticationMethod: .tls(
//                    privateKeyPath: ,
//                    pemPath:
//                ),
//                // Bundle Identifier
//                topic: "de.tum.in.www1.ios.Action-Based-Events-Sample",
//                environment: .sandbox
//            )
            
            defer {
                app.shutdown()
            }
            try app.run()
        } catch {
            print(error)
        }
    }
    
    public init() {
        self.init()
    }
    
    public var version: Version {
        Version()
    }
}


extension Server {
    func register(_ semanticModelBuilders: SemanticModelBuilder...) {
        let visitor = SynaxTreeVisitor(semanticModelBuilders: semanticModelBuilders)
        self.visit(visitor)
    }
    
    private func visit(_ visitor: SynaxTreeVisitor) {
        visitor.enter(collection: self)
        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        visitor.addContext(PathComponentContextKey.self, value: [version], scope: .environment)
        Group {
            content
        }.visit(visitor)
        visitor.exit(collection: self)
    }
}
