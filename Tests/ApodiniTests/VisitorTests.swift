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
    struct TestResponseMediator: ResponseTransformer {
        func transform(response: String) -> String {
            response
        }
    }
    
    struct TestServer: Apodini.Server {
        @ComponentBuilder var content: some Component {
            Group("Test") {
                Text("Hallo Bernd")
                    .httpMethod(.PUT)
                    .response(TestResponseMediator())
            }
            Group("Greetings") {
                Group("Human") {
                    Text("👋")
                        .httpMethod(.GET)
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
        let printVisitor = PrintVisitor()
        TestServer().visit(printVisitor)
    }
    
    func testRESTVisitor() {
        let restVisitor = RESTVisitor(app)
        TestServer().visit(restVisitor)
    }
    
    func testGraphQLVisitor() {
        let graphQLVisitor = GraphQLVisitor(app)
        TestServer().visit(graphQLVisitor)
    }
    
    func testGRPCVisitor() {
        let gRPCVisitor = GRPCVisitor(app)
        TestServer().visit(gRPCVisitor)
    }
    
    func testWebSocketVisitor() {
        let webSocketVisitor = WebSocketVisitor(app)
        TestServer().visit(webSocketVisitor)
    }
}
