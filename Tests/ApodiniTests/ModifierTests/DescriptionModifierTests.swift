//
// Created by Lorena Schlesinger on 10.01.21.
//

import Foundation
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

    func testEndpointDescription() {
        let modelBuilder = SharedSemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [modelBuilder])
        let testComponent = TestComponentDescription()
        Group {
            testComponent.content
        }.accept(visitor)
        visitor.finishParsing()

        // swiftlint:disable force_unwrapping
        let treeNodeA: EndpointsTreeNode = modelBuilder.rootNode.children.first!.children.first!
        let endpoint: AnyEndpoint = treeNodeA.endpoints.first!.value
        
        XCTAssertEqual(endpoint.description, "Returns greeting with name parameter.")
    }
    
    func testEndpointDefaultDescription() {
        let modelBuilder = SharedSemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [modelBuilder])
        let testComponent = TestComponentWithoutDescription()
        Group {
            testComponent.content
        }.accept(visitor)
        visitor.finishParsing()

        // swiftlint:disable force_unwrapping
        let treeNodeA: EndpointsTreeNode = modelBuilder.rootNode.children.first!.children.first!
        let endpoint: AnyEndpoint = treeNodeA.endpoints.first!.value
        
        XCTAssertEqual(endpoint.description, "TestHandler")
    }
}
