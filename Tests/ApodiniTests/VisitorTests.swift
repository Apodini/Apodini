import XCTest
@testable import Apodini
@testable import ApodiniREST


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
}
