import XCTest
@testable import Apodini


final class TreeParserTests: XCTestCase {
    struct TestResponseMediator: ResponseMediator {
        let text: String
        
        init(_ response: String) {
            text = response
        }
    }
    
    func testTreeParser() {
        let treeParser = TreeParser()
        treeParser.parse(
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
                            .httpType(.get)
                    }
                }
            }
        )
    }
}
