//
//  SharedSemanticModelBuilderTests.swift
//  
//
//  Created by Lorena Schlesinger on 06.12.20.
//

@testable import Apodini
import XCTApodini


final class SemanticModelBuilderTests: ApodiniTests {
    struct TestHandler: Handler {
        @Binding
        var name: String
        
        func handle() -> String {
            "Hello \(name)"
        }
    }

    struct TestHandler2: Handler {
        @Binding
        var name: String
        
        @Parameter("someId", .http(.path))
        var id: Int
        
        func handle() -> String {
            "Hello \(name)"
        }
    }
    
    struct TestHandler3: Handler {
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
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        let testComponent = TestComponent()
        Group {
            testComponent.content
        }.accept(visitor)
        visitor.finishParsing()

        let nameParameterId: UUID = try XCTUnwrap(testComponent.$name.parameterId)
        let treeNodeA: EndpointsTreeNode = try XCTUnwrap(modelBuilder.rootNode.children.first)
        let treeNodeB: EndpointsTreeNode = try XCTUnwrap(treeNodeA.children.first { $0.storedPath.description == "b" })
        let treeNodeNameParameter: EndpointsTreeNode = try XCTUnwrap(treeNodeB.children.first)
        let treeNodeSomeOtherIdParameter: EndpointsTreeNode = try XCTUnwrap(treeNodeA.children.first { $0.storedPath.description != "b" })
        let endpointGroupLevel: AnyEndpoint = try XCTUnwrap(treeNodeSomeOtherIdParameter.endpoints.first?.value)
        let someOtherIdParameterId: UUID = try XCTUnwrap(endpointGroupLevel.parameters.first { $0.name == "someOtherId" }?.id)
        let endpoint: AnyEndpoint = try XCTUnwrap(treeNodeNameParameter.endpoints.first?.value)
        
        XCTAssertEqual(treeNodeA.endpoints.count, 0)
        XCTAssertEqual(treeNodeB.endpoints.count, 0)
        XCTAssertEqual(treeNodeNameParameter.endpoints.count, 1)
        XCTAssertEqual(treeNodeSomeOtherIdParameter.endpoints.count, 1)

        XCTAssertEqual(endpointGroupLevel.absolutePath.asPathString(parameterEncoding: .id), "/a/:\(someOtherIdParameterId.uuidString)")
        XCTAssertEqual(endpoint.absolutePath.asPathString(parameterEncoding: .id), "/a/b/:\(nameParameterId.uuidString)")
        XCTAssertTrue(endpoint.parameters.contains { $0.id == nameParameterId })
        XCTAssertEqual(endpoint.parameters.first { $0.id == nameParameterId }?.parameterType, .path)
        
        // test nested use of path parameter that is only set inside `Handler` (i.e. `TestHandler2`)
        let treeNodeSomeIdParameter: EndpointsTreeNode = try XCTUnwrap(treeNodeNameParameter.children.first)
        let nestedEndpoint: AnyEndpoint = try XCTUnwrap(treeNodeSomeIdParameter.endpoints.first?.value)
        let someIdParameterId: UUID = try XCTUnwrap(nestedEndpoint.parameters.first { $0.name == "someId" }?.id)
        
        XCTAssertEqual(nestedEndpoint.parameters.count, 2)
        XCTAssertTrue(nestedEndpoint.parameters.allSatisfy { $0.parameterType == .path })
        XCTAssertEqual(nestedEndpoint.absolutePath.asPathString(parameterEncoding: .id), "/a/b/:\(nameParameterId.uuidString)/:\(someIdParameterId.uuidString)")
    }
}
