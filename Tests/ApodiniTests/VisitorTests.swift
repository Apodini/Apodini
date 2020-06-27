//
//  VisitorTests.swift
//
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
@testable import Apodini
@testable import ApodiniREST
@testable import ApodiniGraphQL
@testable import ApodiniGRPC
@testable import ApodiniWebSocket


final class VisitorTests: XCTestCase {
    struct TestResponseMediator: ResponseMediator {
        let text: String
        
        init(_ response: String) {
            text = response
        }
    }
    
    
    var api: some Component {
        API {
            Group("Test") {
                Text("Hallo")
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
    
    func testPrintVisitor() {
        var printVisitor = PrintVisitor()
        api.visit(&printVisitor)
    }
    
    func testRESTVisitor() {
        var restVisitor = RESTVisitor()
        api.visit(&restVisitor)
    }
    
    func testGraphQLVisitor() {
        var graphQLVisitor = GraphQLVisitor()
        api.visit(&graphQLVisitor)
    }
    
    func testGRPCVisitor() {
        var gRPCVisitor = GRPCVisitor()
        api.visit(&gRPCVisitor)
    }
    
    func testWebSocketVisitor() {
        var webSocketVisitor = WebSocketVisitor()
        api.visit(&webSocketVisitor)
    }
}
