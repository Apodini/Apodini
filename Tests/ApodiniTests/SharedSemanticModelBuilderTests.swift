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
    
    struct TestComponent: Component {
        @PathParameter
        var name: String
        
        var content: some Component {
            Group("a") {
                Group("b", $name) {
                    TestHandler(name: $name)
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
    }
}
