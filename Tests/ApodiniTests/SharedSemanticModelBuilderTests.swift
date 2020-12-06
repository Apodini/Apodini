//
//  SharedSemanticModelBuilderTests.swift
//  
//
//  Created by Lorena Schlesinger on 06.12.20.
//

import XCTest
import Vapor
@testable import Apodini

final class SharedSemanticModelBuilderTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var app: Application!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        app = Application(.testing)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let app = try XCTUnwrap(self.app)
        app.shutdown()
    }
    
    struct TestHandler: Component {
        @Parameter
        var name: String
        
        func handle() -> String {
            "Hello \(name)"
        }
    }
    
    struct TestHandler2: Component {
        @Parameter
        var name: String
        
        @Parameter("someId", .http(.path))
        var id: Int
        
        func handle() -> String {
            "Hello \(name)"
        }
    }
    
    struct TestComponent: Component {
        @PathParameter
        var name: String
        
        var content: some Component {
            Group("a") {
                Group("b", $name) {
                    TestHandler(name: $name)
                    TestHandler2(name: $name)
                }
            }
        }
    }
    
    func testEndpointsTreeNodes() {
        let modelBuilder = SharedSemanticModelBuilder(app)
        let visitor = SynaxTreeVisitor(semanticModelBuilders: [modelBuilder])
        let testComponent = TestComponent()
        Group {
            testComponent.content
        }.visit(visitor)
        
        let nameParameterId: UUID = testComponent.$name.id
        let treeNodeA: EndpointsTreeNode = modelBuilder.endpointsTreeRoot!.children.first!
        let treeNodeB: EndpointsTreeNode = treeNodeA.children.first!
        let treeNodeNameParameter: EndpointsTreeNode = treeNodeB.children.first!
        var endpoint: Endpoint = treeNodeNameParameter.endpoints.first!.value
        
        XCTAssertEqual(treeNodeA.endpoints.count, 0)
        XCTAssertEqual(treeNodeB.endpoints.count, 0)
        XCTAssertEqual(treeNodeNameParameter.endpoints.count, 1)
        XCTAssertEqual(endpoint.pathComponents[0].description, "a")
        XCTAssertEqual(endpoint.pathComponents[1].description, "b")
        XCTAssertEqual(endpoint.pathComponents[2].description, ":\(nameParameterId.uuidString)")
        XCTAssertTrue(endpoint.parameters.contains {$0.id == nameParameterId})
        XCTAssertEqual(endpoint.parameters.first {$0.id == nameParameterId}?.type, .path)
        
        // test nested use of path parameter that is only set inside `Handler` (i.e. `TestHandler2`)
        let treeNodeSomeIdParameter: EndpointsTreeNode = treeNodeNameParameter.children.first!
        var nestedEndpoint: Endpoint = treeNodeSomeIdParameter.endpoints.first!.value
        let someIdParameterId: UUID = nestedEndpoint.parameters.first { $0.name == "someId" }!.id
        
        XCTAssertEqual(nestedEndpoint.parameters.count, 2)
        XCTAssertTrue(nestedEndpoint.parameters.allSatisfy { $0.type == .path })
        XCTAssertEqual(nestedEndpoint.pathComponents[0].description, "a")
        XCTAssertEqual(nestedEndpoint.pathComponents[1].description, "b")
        XCTAssertEqual(nestedEndpoint.pathComponents[2].description, ":\(nameParameterId.uuidString)")
        XCTAssertEqual(nestedEndpoint.pathComponents[3].description, ":\(someIdParameterId.uuidString)")
    }
}
