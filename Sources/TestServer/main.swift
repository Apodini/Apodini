//
//  TestRESTServer.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Vapor

struct TestRESTServer {
    static func main() throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = Application(env)
        
        
        
        defer {
            app.shutdown()
        }
        try app.run()
    }
}

try TestRESTServer.main()
