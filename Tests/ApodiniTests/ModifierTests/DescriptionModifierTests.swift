//
// Created by Lorena Schlesinger on 10.01.21.
//

import XCTest
@testable import Apodini

final class DescriptionModifierTests: ApodiniTests {
    struct TestHandler: Handler {
        @Parameter
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
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        let testComponent = TestComponentDescription()
        Group {
            testComponent.content
        }.accept(visitor)
        visitor.finishParsing()

        let treeNodeA: EndpointsTreeNode = try XCTUnwrap(modelBuilder.rootNode.children.first?.children.first)
        let endpoint: AnyEndpoint = try XCTUnwrap(treeNodeA.endpoints.first?.value)
        let customDescription = endpoint.context.get(valueFor: DescriptionContextKey.self)
    
        XCTAssertEqual(customDescription, "Returns greeting with name parameter.")
    }
    
    func testEndpointDefaultDescription() throws {
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        let testComponent = TestComponentWithoutDescription()
        Group {
            testComponent.content
        }.accept(visitor)
        visitor.finishParsing()
    
        let treeNodeA: EndpointsTreeNode = try XCTUnwrap(modelBuilder.rootNode.children.first?.children.first)
        let endpoint: AnyEndpoint = try XCTUnwrap(treeNodeA.endpoints.first?.value)
        
        XCTAssertEqual(endpoint.description, "TestHandler")
    }
}
