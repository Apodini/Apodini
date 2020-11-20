//
// Created by Andi on 20.11.20.
//

import XCTest
import Vapor
@testable import Apodini

/**
 * Regression test for https://github.com/Apodini/Apodini/issues/12
 */
final class ContextNodeTests: XCTestCase {
    struct TestComponent: Component {
        let type: Int

        init(_ type: Int) {
            self.type = type
        }

        func handle() -> String {
            "\(type)"
        }
    }

    struct TestResponseMediator: ResponseTransformer {
        func transform(response: Never) -> Never {} // uses Never type as it is hooked to the Group
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    var app: Application!

    class func buildStringFromPathComponents(_ components: [Apodini.PathComponent]) -> String {
        StringPathBuilder(components).build()
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        app = Application(.testing)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let app = try XCTUnwrap(self.app)
        app.shutdown()
    }
    
    var groupWithSingleComponent: some Component {
        // What we are trying to do is test that the TestComponent inside the Group actually gets its
        // own ContextNode. In order to check that, we use some ContextKey which uses scope .nextComponent.
        // The ResponseContextKey is currently the only one with scope .nextComponent.
        // If this works correctly the test can check that for the TestComponent no entry for the
        // ResponseContextKey exists. If it gets an non empty array for the ResponseContextKey there is something wrong.

        Group("test") {
            TestComponent(1)
        }.response(TestResponseMediator())
    }

    func testGroupWithSingleComponent() {
        class TestSemanticModelBuilder: SemanticModelBuilder {
            override func register<C: Component>(component: C, withContext context: Context) {
                if let testComponent = component as? TestComponent {
                    let responses = context.get(valueFor: ResponseContextKey.self)

                    switch testComponent.type {
                    case 1:
                        XCTAssertEqual(responses.count, 0, "TestComponent is seemingly sharing the same ContextNode with the Group")
                    default:
                        XCTFail("Received unknown component type \(testComponent.type)")
                    }
                } else {
                    XCTFail("Received registration for unexpected component type \(component)")
                }
            }
        }

        let visitor = SynaxTreeVisitor(semanticModelBuilders: [TestSemanticModelBuilder(app)])
        groupWithSingleComponent.visit(visitor)
    }
    
    var groupWithComponentAndGroup: some Component {
        Group("test") {
            TestComponent(1)
                .httpMethod(.GET)
            Group("test2") {
                TestComponent(2)
            }.httpMethod(.DELETE)
        }.httpMethod(.POST)
    }

    func testGroupWithComponentAndGroup() {
        class TestSemanticModelBuilder: SemanticModelBuilder {
            override func register<C: Component>(component: C, withContext context: Context) {
                if let testComponent = component as? TestComponent {
                    let path = context.get(valueFor: PathComponentContextKey.self)
                    let pathString = ContextNodeTests.buildStringFromPathComponents(path)
                    let httpMethod = context.get(valueFor: HTTPMethodContextKey.self)

                    switch testComponent.type {
                    case 1:
                        XCTAssertEqual(pathString, "test")
                        XCTAssertEqual(httpMethod, .GET)
                    case 2:
                        XCTAssertEqual(pathString, "test/test2")
                        XCTAssertEqual(httpMethod, .DELETE)
                    default:
                        XCTFail("Received unknown component type \(testComponent.type)")
                    }
                } else {
                    XCTFail("Received registration for unexpected component type \(component)")
                }
            }
        }

        let visitor = SynaxTreeVisitor(semanticModelBuilders: [TestSemanticModelBuilder(app)])
        groupWithComponentAndGroup.visit(visitor)
    }
    
    var groupWithGroupAndComponent: some Component {
        Group("test") {
            Group("test2") {
                TestComponent(2)
            }.httpMethod(.POST)
            TestComponent(1)
        }
    }

    func testGroupWithGroupAndComponent() {
        class TestSemanticModelBuilder: SemanticModelBuilder {
            override func register<C: Component>(component: C, withContext context: Context) {
                if let testComponent = component as? TestComponent {
                    let path = context.get(valueFor: PathComponentContextKey.self)
                    let pathString = ContextNodeTests.buildStringFromPathComponents(path)
                    let httpMethod = context.get(valueFor: HTTPMethodContextKey.self)

                    switch testComponent.type {
                    case 1:
                        XCTAssertEqual(pathString, "test")
                        XCTAssertEqual(httpMethod, .GET)
                    case 2:
                        XCTAssertEqual(pathString, "test/test2")
                        XCTAssertEqual(httpMethod, .POST)
                    default:
                        XCTFail("Received unknown component type \(testComponent.type)")
                    }
                } else {
                    XCTFail("Received registration for unexpected component type \(component)")
                }
            }
        }

        let visitor = SynaxTreeVisitor(semanticModelBuilders: [TestSemanticModelBuilder(app)])
        groupWithGroupAndComponent.visit(visitor)
    }
}
