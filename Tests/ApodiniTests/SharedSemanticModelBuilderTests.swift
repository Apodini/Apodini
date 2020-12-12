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
    
    struct TestHandler3: Component {
        @Parameter("someOtherId", .http(.path))
        var id: Int
        
        func handle() -> String {
            "Hello Test Handler 3"
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
                TestHandler3()
            }
        }
    }
    
    func testEndpointsTreeNodes() throws {
        // swiftlint:disable force_unwrapping
        let modelBuilder = SharedSemanticModelBuilder(app)
        let visitor = SynaxTreeVisitor(semanticModelBuilders: [modelBuilder])
        let testComponent = TestComponent()
        Group {
            testComponent.content
        }.visit(visitor)
        
        let nameParameterId: UUID = testComponent.$name.id
        
        let treeNodeA: EndpointsTreeNode = modelBuilder.endpointsTreeRoot!.children.first!
        let treeNodeB: EndpointsTreeNode = treeNodeA.children.first { $0.path.description == "b" }!
        let treeNodeNameParameter: EndpointsTreeNode = treeNodeB.children.first!
        let treeNodeSomeOtherIdParameter: EndpointsTreeNode = treeNodeA.children.first { $0.path.description != "b" }!
        var endpointGroupLevel: Endpoint = treeNodeSomeOtherIdParameter.endpoints.first!.value
        let someOtherIdParameterId: UUID = endpointGroupLevel.parameters.first { $0.name == "someOtherId" }!.id
        var endpoint: Endpoint = treeNodeNameParameter.endpoints.first!.value
        
        XCTAssertEqual(treeNodeA.endpoints.count, 0)
        XCTAssertEqual(treeNodeB.endpoints.count, 0)
        XCTAssertEqual(treeNodeNameParameter.endpoints.count, 1)
        XCTAssertEqual(treeNodeSomeOtherIdParameter.endpoints.count, 1)
        XCTAssertEqual(endpointGroupLevel.absolutePath[0].description, "a")
        XCTAssertEqual(endpointGroupLevel.absolutePath[1].description, ":\(someOtherIdParameterId.uuidString)")
        XCTAssertEqual(endpoint.absolutePath[0].description, "a")
        XCTAssertEqual(endpoint.absolutePath[1].description, "b")
        XCTAssertEqual(endpoint.absolutePath[2].description, ":\(nameParameterId.uuidString)")
        XCTAssertTrue(endpoint.parameters.contains { $0.id == nameParameterId })
        XCTAssertEqual(endpoint.parameters.first { $0.id == nameParameterId }?.parameterType, .path)
        
        // test nested use of path parameter that is only set inside `Handler` (i.e. `TestHandler2`)
        let treeNodeSomeIdParameter: EndpointsTreeNode = treeNodeNameParameter.children.first!
        var nestedEndpoint: Endpoint = treeNodeSomeIdParameter.endpoints.first!.value
        let someIdParameterId: UUID = nestedEndpoint.parameters.first { $0.name == "someId" }!.id
        
        XCTAssertEqual(nestedEndpoint.parameters.count, 2)
        XCTAssertTrue(nestedEndpoint.parameters.allSatisfy { $0.parameterType == .path })
        XCTAssertEqual(nestedEndpoint.absolutePath[0].description, "a")
        XCTAssertEqual(nestedEndpoint.absolutePath[1].description, "b")
        XCTAssertEqual(nestedEndpoint.absolutePath[2].description, ":\(nameParameterId.uuidString)")
        XCTAssertEqual(nestedEndpoint.absolutePath[3].description, ":\(someIdParameterId.uuidString)")
    }
    
    struct TestHandler4: Component {
        func handle() -> String {
            "Hello Test Handler 4"
        }
    }
    
    struct TestComponent2: Component {
        @PathParameter
        var name: String
        
        var content: some Component {
            Group($name) {
                TestHandler4()
            }
        }
    }
    
    func testEndpointsTreeNodes_implicitPathParameter() throws {
        // swiftlint:disable force_unwrapping
        let modelBuilder = SharedSemanticModelBuilder(app)
        let visitor = SynaxTreeVisitor(semanticModelBuilders: [modelBuilder])
        let testComponent = TestComponent2()
        Group {
            testComponent.content
        }.visit(visitor)
        
        let nameParameterId: UUID = testComponent.$name.id
        
        let treeNode: EndpointsTreeNode = modelBuilder.endpointsTreeRoot!.children.first!
        var endpoint: Endpoint = treeNode.endpoints.first!.value
        
        XCTAssertEqual(treeNode.endpoints.count, 1)
        XCTAssertEqual(endpoint.parameters.count, 1)
        XCTAssertEqual(endpoint.absolutePath[0].description, ":\(nameParameterId.uuidString)")
    }
}
