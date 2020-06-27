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
    
    
    func api() -> some Component {
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
        let testAPI = api()
        testAPI.visit(&printVisitor)
    }
    
    func testRESTVisitor() {
        var printVisitor = RESTVisitor()
        let testAPI = api()
        testAPI.visit(&printVisitor)
    }
    
    func testGraphQLVisitor() {
        var printVisitor = GraphQLVisitor()
        let testAPI = api()
        testAPI.visit(&printVisitor)
    }
    
    func testGRPCVisitor() {
        var printVisitor = GRPCVisitor()
        let testAPI = api()
        testAPI.visit(&printVisitor)
    }
    
    func testWebSocketVisitor() {
        var printVisitor = WebSocketVisitor()
        let testAPI = api()
        testAPI.visit(&printVisitor)
    }
}
