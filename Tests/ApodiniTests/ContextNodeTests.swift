//
// Created by Andi on 20.11.20.
//

import XCTest
import Vapor
@testable import Apodini



struct TestComponent: Handler {
    let __endpointId = AnyEndpointIdentifier(Self.self)
    
    let type: Int

    init(_ type: Int) {
        self.type = type
    }

    func handle() -> String {
        "\(type)"
    }
}



struct IntEnvironmentContextKey: ContextKey {
    static var defaultValue: Int = 0

    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = nextValue()
    }
}



struct IntNextComponentContextKey: ContextKey {
    static var defaultValue: Int = 0

    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = nextValue()
    }
}



struct IntModifier<C: Component>: Modifier, Visitable {
    let component: C
    let scope: Scope
    let value: Int

    init(_ component: C, scope: Scope, value: Int) {
        self.component = component
        self.scope = scope
        self.value = value
    }

    func visit(_ visitor: SyntaxTreeVisitor) {
        switch scope {
        case .environment:
            visitor.addContext(IntEnvironmentContextKey.self, value: value, scope: .environment)
        case .nextComponent:
            visitor.addContext(IntNextComponentContextKey.self, value: value, scope: .nextComponent)
        }
        component.visit(visitor)
    }
}


extension IntModifier: Handler, HandlerModifier where ModifiedComponent: Handler {
    typealias Response = ModifiedComponent.Response
}


extension Component {
    func modifier(_ scope: Scope, value: Int) -> IntModifier<Self> {
        IntModifier(self, scope: scope, value: value)
    }
}




/**
 * Regression test for https://github.com/Apodini/Apodini/issues/12
 */
final class ContextNodeTests: XCTestCase {
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
        Group("test") {
            TestComponent(1)
        }.modifier(.nextComponent, value: 1)
    }

    func testGroupWithSingleComponent() {
        class TestSemanticModelBuilder: SemanticModelBuilder {
            override func register<C: Handler>(component: C, withContext context: Context) {
                if let testComponent = component as? TestComponent {
                    let localInt = context.get(valueFor: IntNextComponentContextKey.self)

                    switch testComponent.type {
                    case 1:
                        // 0 is the default value for IntNextComponentContextKey
                        XCTAssertEqual(localInt, 0, "TestComponent is seemingly sharing the same ContextNode with the Group")
                    default:
                        XCTFail("Received unknown component type \(testComponent.type)")
                    }
                } else {
                    XCTFail("Received registration for unexpected component type \(component)")
                }
            }
        }

        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [TestSemanticModelBuilder(app)])
        groupWithSingleComponent.visit(visitor)
    }
    
    
    var groupWithComponentAndGroup: some Component {
        Group("test") {
            TestComponent(1)
                .modifier(.environment, value: 1)
            Group("test2") {
                TestComponent(2)
            }.modifier(.environment, value: 2)
        }.modifier(.environment, value: 3)
    }

    func testGroupWithComponentAndGroup() {
        class TestSemanticModelBuilder: SemanticModelBuilder {
            override func register<C: Handler>(component: C, withContext context: Context) {
                if let testComponent = component as? TestComponent {
                    let path = context.get(valueFor: PathComponentContextKey.self)
                    let pathString = ContextNodeTests.buildStringFromPathComponents(path)
                    let environmentInt = context.get(valueFor: IntEnvironmentContextKey.self)

                    switch testComponent.type {
                    case 1:
                        XCTAssertEqual(pathString, "test")
                        XCTAssertEqual(environmentInt, 1)
                    case 2:
                        XCTAssertEqual(pathString, "test/test2")
                        XCTAssertEqual(environmentInt, 2)
                    default:
                        XCTFail("Received unknown component type \(testComponent.type)")
                    }
                } else {
                    XCTFail("Received registration for unexpected component type \(component)")
                }
            }
        }

        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [TestSemanticModelBuilder(app)])
        groupWithComponentAndGroup.visit(visitor)
    }
    
    
    var groupWithGroupAndComponent: some Component {
        Group("test") {
            Group("test2") {
                TestComponent(2)
            }.modifier(.environment, value: 1)
            TestComponent(1)
        }
    }

    func testGroupWithGroupAndComponent() {
        class TestSemanticModelBuilder: SemanticModelBuilder {
            override func register<C: Handler>(component: C, withContext context: Context) {
                if let testComponent = component as? TestComponent {
                    let path = context.get(valueFor: PathComponentContextKey.self)
                    let pathString = ContextNodeTests.buildStringFromPathComponents(path)
                    let environmentInt = context.get(valueFor: IntEnvironmentContextKey.self)

                    switch testComponent.type {
                    case 1:
                        XCTAssertEqual(pathString, "test")
                        XCTAssertEqual(environmentInt, 0) // 0 is the default value for IntEnvironmentContextKey
                    case 2:
                        XCTAssertEqual(pathString, "test/test2")
                        XCTAssertEqual(environmentInt, 1)
                    default:
                        XCTFail("Received unknown component type \(testComponent.type)")
                    }
                } else {
                    XCTFail("Received registration for unexpected component type \(component)")
                }
            }
        }

        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [TestSemanticModelBuilder(app)])
        groupWithGroupAndComponent.visit(visitor)
    }
}
