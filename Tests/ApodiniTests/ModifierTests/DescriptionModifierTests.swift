//
// Created by Lorena Schlesinger on 10.01.21.
//

import XCTest
@testable import Apodini

final class DescriptionModifierTests: XCTApodiniDatabaseBirdTest {
    struct TestHandler: Handler {
        @Binding
        var name: String

        func handle() -> String {
            "Hello \(name)"
        }
    }

    struct TestComponentDescription: Component {
        @PathParameter
        var name: String

        var content: some Component {
            Group("a", $name) {
                TestHandler(name: $name)
                    .description("Returns greeting with name parameter.")
            }
        }
    }
    
    struct TestComponentWithoutDescription: Component {
        @PathParameter
        var name: String

        var content: some Component {
            Group("a", $name) {
                TestHandler(name: $name)
            }
        }
    }

    func testEndpointDescription() throws {
        let endpoint = try XCTCreateMockEndpoint(handlerType: TestHandler.self) {
            TestComponentDescription()
        }
        let customDescription = endpoint[Context.self].get(valueFor: DescriptionContextKey.self)
        XCTAssertEqual(customDescription, "Returns greeting with name parameter.")
    }
    
    func testEndpointDefaultDescription() throws {
        let endpoint = try XCTCreateMockEndpoint(handlerType: TestHandler.self) {
            TestComponentWithoutDescription()
        }
        XCTAssertEqual(endpoint.description, "TestHandler")
    }
}
