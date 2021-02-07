//
// Created by Lorena Schlesinger on 10.01.21.
//

import XCTest
@testable import Apodini
@testable import ApodiniOpenAPI

final class TagModifierTests: ApodiniTests {
    struct TestHandler: Handler {
        @Parameter
        var name: String

        func handle() -> String {
            "Hello \(name)"
        }
    }

    struct TestComponentTag: Component {
        @PathParameter
        var name: String

        var content: some Component {
            Group("register", $name) {
                TestHandler(name: $name)
                    .tags("People_Register")
            }
        }
    }

    func testEndpointTag() throws {
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        let testComponent = TestComponentTag()
        Group {
            testComponent.content
        }.accept(visitor)
        visitor.finishParsing()

        let treeNodeA: EndpointsTreeNode = try XCTUnwrap(modelBuilder.rootNode.children.first?.children.first)
        let endpoint: AnyEndpoint = try XCTUnwrap(treeNodeA.endpoints.first?.value)
        let tags = endpoint.context.get(valueFor: TagContextKey.self)
    
        XCTAssertEqual(tags, ["People_Register"])
    }
}
