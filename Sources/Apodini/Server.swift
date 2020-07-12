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
            
            let graphQLVisitor = GraphQLVisitor(app)
            server.visit(graphQLVisitor)
            
            let gRPCVisitor = GRPCVisitor(app)
            server.visit(gRPCVisitor)
            
            let restVisitor = RESTVisitor(app)
            server.visit(restVisitor)
            
            let webSocketVisitor = WebSocketVisitor(app)
            server.visit(webSocketVisitor)
            
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
    func visit(_ visitor: Visitor) {
        visitor.enter(collection: self)
        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        visitor.addContext(PathComponentContextKey.self, value: [version], scope: .environment)
        Group {
            content
        }.visit(visitor)
        visitor.exit(collection: self)
    }
}
