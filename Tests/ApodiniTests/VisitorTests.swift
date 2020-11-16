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
        let visitor = SynaxTreeVisitor(semanticModelBuilders: [RESTSemanticModelBuilder(app)])
        TestServer().visit(visitor)
    }
    
    func testGraphQLVisitor() {
        let visitor = SynaxTreeVisitor(semanticModelBuilders: [GraphQLSemanticModelBuilder(app)])
        TestServer().visit(visitor)
    }
    
    func testGRPCVisitor() {
        let visitor = SynaxTreeVisitor(semanticModelBuilders: [GRPCSemanticModelBuilder(app)])
        TestServer().visit(visitor)
    }
    
    func testWebSocketVisitor() {
        let visitor = SynaxTreeVisitor(semanticModelBuilders: [WebSocketSemanticModelBuilder(app)])
        TestServer().visit(visitor)
    }
    
    func testOpenAPIVisitor() {
        let visitor = SynaxTreeVisitor(semanticModelBuilders: [OpenAPISemanticModelBuilder(app)])
        TestServer().visit(visitor)
    }
}
