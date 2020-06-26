import XCTest
@testable import Apodini


final class VisitorTests: XCTestCase {
    struct TestResponseMediator: ResponseMediator {
        let text: String
        
        init(_ response: String) {
            text = response
        }
    }
    
    
    func api() -> some Component {
        API(version: 1) {
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
    
    func testTreeParser() {
        var printVisitor = PrintVisitor()
        let testAPI = api()
        testAPI.visit(&printVisitor)
    }
}
