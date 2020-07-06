//
//  VisitorTests.swift
//
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import Vapor
@testable import Apodini


final class VisitorTests: XCTestCase {
    struct TestResponseMediator: ResponseMediator {
        let text: String
        
        init(_ response: String) {
            text = response
        }
    }
    
    struct TestServer: Apodini.Server {
        @ComponentBuilder var content: some Component {
            Group("Test") {
                Text("Hallo Bernd")
                    .httpType(.put)
                    .response(TestResponseMediator.self)
            }
            Group("Greetings") {
                Group("Human") {
                    Text("👋")
                        .httpType(.get)
                }
                Group("Plant") {
                    Text("🍀")
                }
            }
        }
    }
    
    var app: Application!
    
    
    override func setUp() {
        app = Application(.testing)
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    func testPrintVisitor() {
        var printVisitor = PrintVisitor()
        TestServer().visit(&printVisitor)
    }
    
    func testRESTVisitor() {
        var restVisitor = RESTVisitor(app)
        TestServer().visit(&restVisitor)
    }
    
    func testGraphQLVisitor() {
        var graphQLVisitor = GraphQLVisitor(app)
        TestServer().visit(&graphQLVisitor)
    }
    
    func testGRPCVisitor() {
        var gRPCVisitor = GRPCVisitor(app)
        TestServer().visit(&gRPCVisitor)
    }
    
    func testWebSocketVisitor() {
        var webSocketVisitor = WebSocketVisitor(app)
        TestServer().visit(&webSocketVisitor)
    }
}
