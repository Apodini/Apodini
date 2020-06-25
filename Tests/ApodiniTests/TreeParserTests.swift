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
            API {
                Text("Hallo")
                    .httpType(.put)
                // Question: How do I achieve that this is possible? I would suspect this is connected to the issue that I can only define a modifier with a concrete type ...
                //     .response(TestResponseMediator.self)
                Text("World")
                    .httpType(.get)
            }
        )
    }
}
