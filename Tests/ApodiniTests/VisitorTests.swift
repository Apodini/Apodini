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
    
    struct TestWebService: Apodini.WebService {
        @ComponentBuilder var content: some Component {
            Group("Test") {
                Text("Hallo Bernd")
                    .operation(.update)
                    .response(TestResponseMediator())
            }
            Group("Greetings") {
                Group("Human") {
                    Text("👋")
                        .operation(.read)
                }
                Group("Plant") {
                    Text("🍀")
                }
            }
        }
    }
    

    // swiftlint:disable:next implicitly_unwrapped_optional
    var app: Application!
    
    
    override func setUp() {
        super.setUp()
        app = Application(.testing)
    }
    
    override func tearDown() {
        super.tearDown()
        app.shutdown()
    }
    
    func testPrintVisitor() {
        let printVisitor = PrintVisitor()
        TestWebService().visit(printVisitor)
    }
    
    func testRESTVisitor() {
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [SharedSemanticModelBuilder(app, interfaceExporters: RESTInterfaceExporter.self)])
        TestWebService().visit(visitor)
    }
    
    func testGraphQLVisitor() {
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [GraphQLSemanticModelBuilder(app)])
        TestWebService().visit(visitor)
    }
    
    func testGRPCVisitor() {
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [GRPCSemanticModelBuilder(app)])
        TestWebService().visit(visitor)
    }
    
    func testWebSocketVisitor() {
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [SharedSemanticModelBuilder(app, interfaceExporters: WebSocketInterfaceExporter.self)])
        TestWebService().visit(visitor)
    }
    
    func testOpenAPIVisitor() {
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [OpenAPISemanticModelBuilder(app)])
        TestWebService().visit(visitor)
    }
}
