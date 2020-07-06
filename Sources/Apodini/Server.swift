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
            
            var graphQLVisitor = GraphQLVisitor(app)
            server.visit(&graphQLVisitor)
            
            var gRPCVisitor = GRPCVisitor(app)
            server.visit(&gRPCVisitor)
            
            var restVisitor = RESTVisitor(app)
            server.visit(&restVisitor)
            
            var webSocketVisitor = WebSocketVisitor(app)
            server.visit(&webSocketVisitor)
            
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
        Version(prefix: "api", major: 1)
    }
    
    
    public func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.enter(collection: self)
        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        visitor.addContext(PathComponentContextKey.self, value: [version], scope: .environment)
        Group {
            content
        }.visit(&visitor)
        visitor.exit(collection: self)
    }
}
