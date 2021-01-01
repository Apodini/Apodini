//
//  VisitorTests.swift
//
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
@testable import Apodini


final class VisitorTests: ApodiniTests {
    struct TestResponseMediator: ResponseTransformer {
        func transform(response: String) -> String {
            response
        }
    }
    
    struct TestWebService: WebService {
        @ComponentBuilder
        var content: some Component {
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
    
    func testRESTVisitor() {
        #warning("Set up some expectations")
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [SharedSemanticModelBuilder(app).with(exporter: RESTInterfaceExporter.self)])
        TestWebService().accept(visitor)
    }
    
    func testGraphQLVisitor() {
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [GraphQLSemanticModelBuilder(app)])
        TestWebService().accept(visitor)
    }
    
    func testGRPCVisitor() {
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [SharedSemanticModelBuilder(app).with(exporter: GRPCInterfaceExporter.self)])
        TestWebService().accept(visitor)
    }
    
    func testWebSocketVisitor() {
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [WebSocketSemanticModelBuilder(app)])
        TestWebService().accept(visitor)
    }
    
    func testOpenAPIVisitor() {
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [OpenAPISemanticModelBuilder(app)])
        TestWebService().accept(visitor)
    }
}
