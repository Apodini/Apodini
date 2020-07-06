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
    
    
    var app: Application!
    
    
    var api: some Component {
        API {
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
    
    override func setUp() {
        app = Application(.testing)
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    func testPrintVisitor() {
        var printVisitor = PrintVisitor()
        api.visit(&printVisitor)
    }
    
    func testRESTVisitor() {
        var restVisitor = RESTVisitor(app)
        api.visit(&restVisitor)
    }
    
    func testGraphQLVisitor() {
        var graphQLVisitor = GraphQLVisitor(app)
        api.visit(&graphQLVisitor)
    }
    
    func testGRPCVisitor() {
        var gRPCVisitor = GRPCVisitor(app)
        api.visit(&gRPCVisitor)
    }
    
    func testWebSocketVisitor() {
        var webSocketVisitor = WebSocketVisitor(app)
        api.visit(&webSocketVisitor)
    }
}
