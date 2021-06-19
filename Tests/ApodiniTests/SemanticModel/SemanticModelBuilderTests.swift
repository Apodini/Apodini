//
//  SharedSemanticModelBuilderTests.swift
//  
//
//  Created by Lorena Schlesinger on 06.12.20.
//

@testable import Apodini
@testable import ApodiniREST
import Vapor
import XCTApodini


final class SemanticModelBuilderTests: ApodiniTests {
    struct TestHandler: Handler {
        @Binding
        var name: String
        
        func handle() -> String {
            "Hello \(name)"
        }
    }

    struct PrintGuard: SyncGuard {
        func check() {
            print("PrintGuard check executed")
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

    struct TestHandler4: Handler {
        func handle() -> String {
            "Hello Test Handler 4"
        }
    }

    struct ResponseHandler1: Handler {
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

    struct ResponseHandler2: Handler {
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
        let exporter = RESTInterfaceExporter(app)
        let handler = TestHandler4()
        let endpoint = handler.mockEndpoint()
        let context = endpoint.createConnectionContext(for: exporter)

        let request = Vapor.Request(application: app.vapor.app,
                                    method: .GET,
                                    url: "",
                                    on: app.eventLoopGroup.next())
        let expectedString = "Hello Test Handler 4"

        try XCTCheckResponse(
            context.handle(request: request),
            content: expectedString,
            connectionEffect: .close
        )
    }

    func testResponsePassthrough_send() throws {
        let exporter = RESTInterfaceExporter(app)
        let handler = ResponseHandler1()
        let endpoint = handler.mockEndpoint(app: app)
        let context = endpoint.createConnectionContext(for: exporter)
        let request = Vapor.Request(application: app.vapor.app,
                                    method: .GET,
                                    url: "",
                                    on: app.eventLoopGroup.next())

        try XCTCheckResponse(
            context.handle(request: request, final: false),
            content: "Send",
            connectionEffect: .open
        )
    }

    func testResponsePassthrough_final() throws {
        let mockRequest = MockRequest.createRequest(running: app.eventLoopGroup.next(), queuedParameters: .none)
        let exporter = RESTInterfaceExporter(app)
        let handler = ResponseHandler1().environment(Connection(state: .end, request: mockRequest), for: \Apodini.Application.connection)
        let endpoint = handler.mockEndpoint(app: app)
        let context = endpoint.createConnectionContext(for: exporter)
        let request = Vapor.Request(application: app.vapor.app,
                                    method: .GET,
                                    url: "",
                                    on: app.eventLoopGroup.next())
        
        try XCTCheckResponse(
            context.handle(request: request),
            content: "Final",
            connectionEffect: .close
        )
    }

    func testResponsePassthrough_nothing() throws {
        let exporter = RESTInterfaceExporter(app)
        let handler = ResponseHandler2()
        let endpoint = handler.mockEndpoint(app: app)
        let context = endpoint.createConnectionContext(for: exporter)
        let request = Vapor.Request(application: app.vapor.app,
                                    method: .GET,
                                    url: "",
                                    on: app.eventLoopGroup.next())

        try XCTCheckResponse(
            context.handle(request: request, final: false),
            Empty.self,
            content: nil,
            connectionEffect: .open
        )
    }

    func testResponsePassthrough_end() throws {
        let mockRequest = MockRequest.createRequest(running: app.eventLoopGroup.next(), queuedParameters: .none)
        let exporter = RESTInterfaceExporter(app)
        let handler = ResponseHandler2().environment(Connection(state: .end, request: mockRequest), for: \Apodini.Application.connection)
        let endpoint = handler.mockEndpoint(app: app)
        let context = endpoint.createConnectionContext(for: exporter)
        let request = Vapor.Request(application: app.vapor.app,
                                    method: .GET,
                                    url: "",
                                    on: app.eventLoopGroup.next())

        try XCTCheckResponse(
            context.handle(request: request),
            Empty.self,
            content: nil,
            connectionEffect: .close
        )
    }
}
