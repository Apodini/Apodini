//
//  SharedSemanticModelBuilderTests.swift
//  
//
//  Created by Lorena Schlesinger on 06.12.20.
//

@testable import Apodini
import XCTApodiniHTTP


final class SemanticModelBuilderTests: XCTApodiniHTTPTest {
    private struct TestHandler: Handler {
        @Binding
        var name: String
        
        func handle() -> String {
            "Hello \(name)"
        }
    }

    private struct TestHandler2: Handler {
        @Binding
        var name: String
        
        @Parameter("someId", .http(.path))
        var id: Int
        
        func handle() -> String {
            "Hello \(name)"
        }
    }
    
    private struct TestHandler3: Handler {
        @Parameter("someOtherId", .http(.path))
        var id: Int
        
        func handle() -> String {
            "Hello Test Handler 3"
        }
    }

    private struct TestHandler4: Handler {
        func handle() -> String {
            "Hello Test Handler 4"
        }
    }

    private struct ResponseHandler1: Handler {
        @Apodini.Environment(\.connection)
        var connection: Connection

        func handle() -> Apodini.Response<String> {
            switch connection.state {
            case .open:
                return .send("Send")
            default:
                return .final("Final")
            }
        }
    }

    private struct ResponseHandler2: Handler {
        @Apodini.Environment(\.connection)
        var connection: Connection

        func handle() -> Apodini.Response<String> {
            switch connection.state {
            case .open:
                return .nothing
            default:
                return .end
            }
        }
    }
    
    private struct TestComponent: Component {
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
        let globalBlackboard = GlobalBlackboard<LazyHashmapBlackboard>(app)
        let model = globalBlackboard[RelationshipModelKnowledgeSource.self].model
        
        XCTAssertEqual(model.root.collectEndpoints().count, 3)
        
        let treeNodeA: EndpointsTreeNode = model.root.children.first!
        let treeNodeB: EndpointsTreeNode = treeNodeA.children.first { $0.storedPath.description == "b" }!
        let treeNodeNameParameter: EndpointsTreeNode = treeNodeB.children.first!
        let treeNodeSomeOtherIdParameter: EndpointsTreeNode = treeNodeA.children.first { $0.storedPath.description != "b" }!
        let endpointGroupLevel: AnyRelationshipEndpoint = treeNodeSomeOtherIdParameter.endpoints.first!.value
        let someOtherIdParameterId: UUID = endpointGroupLevel.parameters.first { $0.name == "someOtherId" }!.id
        let endpoint: AnyRelationshipEndpoint = treeNodeNameParameter.endpoints.first!.value
        
        XCTAssertEqual(treeNodeA.endpoints.count, 0)
        XCTAssertEqual(treeNodeB.endpoints.count, 0)
        XCTAssertEqual(treeNodeNameParameter.endpoints.count, 1)
        XCTAssertEqual(treeNodeSomeOtherIdParameter.endpoints.count, 1)

        XCTAssertEqual(endpointGroupLevel.absolutePath.asPathString(parameterEncoding: .id), "/a/:\(someOtherIdParameterId.uuidString)")
        XCTAssertEqual(endpoint.absolutePath.asPathString(parameterEncoding: .id), "/a/b/:\(nameParameterId.uuidString)")
        XCTAssertTrue(endpoint.parameters.contains { $0.id == nameParameterId })
        XCTAssertEqual(endpoint.parameters.first { $0.id == nameParameterId }?.parameterType, .path)
        
        // test nested use of path parameter that is only set inside `Handler` (i.e. `TestHandler2`)
        let treeNodeSomeIdParameter: EndpointsTreeNode = treeNodeNameParameter.children.first!
        let nestedEndpoint: AnyRelationshipEndpoint = treeNodeSomeIdParameter.endpoints.first!.value
        let someIdParameterId: UUID = nestedEndpoint.parameters.first { $0.name == "someId" }!.id
        
        XCTAssertEqual(nestedEndpoint.parameters.count, 2)
        XCTAssertTrue(nestedEndpoint.parameters.allSatisfy { $0.parameterType == .path })
        XCTAssertEqual(nestedEndpoint.absolutePath.asPathString(parameterEncoding: .id), "/a/b/:\(nameParameterId.uuidString)/:\(someIdParameterId.uuidString)")
    }
    
    func testShouldWrapInFinalByDefault() throws {
        try XCTCheckHandler(TestHandler4()) {
            MockRequest(expectation: "Hello Test Handler 4")
        }
    }

    func testResponsePassthrough_send() throws {
        try XCTCheckHandler(ResponseHandler1()) {
            MockRequest(connectionState: .open, expectation: .response(status: .ok, connectionEffect: .open, "Send"))
        }
    }

    func testResponsePassthrough_final() throws {
        try XCTCheckHandler(ResponseHandler1()) {
            MockRequest(connectionState: .end, expectation: .response(status: .ok, connectionEffect: .close, "Final"))
        }
    }

    func testResponsePassthrough_nothing() throws {
        try XCTCheckHandler(ResponseHandler2()) {
            MockRequest<String>(connectionState: .open, expectation: .response(connectionEffect: .open, nil))
        }
    }

    func testResponsePassthrough_end() throws {
        try XCTCheckHandler(ResponseHandler2()) {
            MockRequest<String>(connectionState: .end, expectation: .response(connectionEffect: .close, nil))
        }
    }
}
