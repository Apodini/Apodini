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

    struct PrintGuard: SyncGuard {
        @_Request
        var request: Apodini.Request

        func check() {
            print(request.description)
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

    struct ActionHandler1: Component {
        @Apodini.Environment(\.connection)
        var connection: Connection

        @Parameter
        var name: String

        func handle() -> Action<String> {
            switch connection.state {
            case .open:
                return .send("Hello \(name)")
            default:
                return .final("Bye \(name)")
            }
        }
    }

    struct ActionHandler2: Component {
        @Apodini.Environment(\.connection)
        var connection: Connection

        func handle() -> Action<String> {
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

    struct EmojiMediator: ResponseTransformer {
        private let emojis: String

        init(emojis: String = "✅") {
            self.emojis = emojis
        }

        func transform(response: String) -> String {
            "\(emojis) \(response) \(emojis)"
        }
    }
    
    func testEndpointsTreeNodes() {
        // swiftlint:disable force_unwrapping
        // swiftlint:disable force_cast
        let modelBuilder = SharedSemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [modelBuilder])
        let testComponent = TestComponent()
        Group {
            testComponent.content
        }.visit(visitor)
        
        let nameParameterId: UUID = testComponent.$name.id
        let treeNodeA: EndpointsTreeNode = modelBuilder.rootNode.children.first!
        let treeNodeB: EndpointsTreeNode = treeNodeA.children.first { $0.path.description == "b" }!
        let treeNodeNameParameter: EndpointsTreeNode = treeNodeB.children.first!
        let treeNodeSomeOtherIdParameter: EndpointsTreeNode = treeNodeA.children.first { $0.path.description != "b" }!
        let endpointGroupLevel: Endpoint = treeNodeSomeOtherIdParameter.endpoints.first!.value
        let someOtherIdParameterId: UUID = endpointGroupLevel.parameters.first { $0.name == "someOtherId" }!.id
        let endpoint: Endpoint = treeNodeNameParameter.endpoints.first!.value
        
        XCTAssertEqual(treeNodeA.endpoints.count, 0)
        XCTAssertEqual(treeNodeB.endpoints.count, 0)
        XCTAssertEqual(treeNodeNameParameter.endpoints.count, 1)
        XCTAssertEqual(treeNodeSomeOtherIdParameter.endpoints.count, 1)
        XCTAssertEqual(endpointGroupLevel.absolutePath[0].description, "a")
        XCTAssertEqual(endpointGroupLevel.absolutePath[1].description, ":\(someOtherIdParameterId.uuidString)")
        XCTAssertNoThrow(endpointGroupLevel.absolutePath[1] as! Parameter<Int>)
        XCTAssertEqual((endpointGroupLevel.absolutePath[1] as! Parameter<Int>).id, someOtherIdParameterId)
        XCTAssertEqual(endpoint.absolutePath[0].description, "a")
        XCTAssertEqual(endpoint.absolutePath[1].description, "b")
        XCTAssertEqual(endpoint.absolutePath[2].description, ":\(nameParameterId.uuidString)")
        XCTAssertTrue(endpoint.parameters.contains { $0.id == nameParameterId })
        XCTAssertEqual(endpoint.parameters.first { $0.id == nameParameterId }?.parameterType, .path)
        
        // test nested use of path parameter that is only set inside `Handler` (i.e. `TestHandler2`)
        let treeNodeSomeIdParameter: EndpointsTreeNode = treeNodeNameParameter.children.first!
        let nestedEndpoint: Endpoint = treeNodeSomeIdParameter.endpoints.first!.value
        let someIdParameterId: UUID = nestedEndpoint.parameters.first { $0.name == "someId" }!.id
        
        XCTAssertEqual(nestedEndpoint.parameters.count, 2)
        XCTAssertTrue(nestedEndpoint.parameters.allSatisfy { $0.parameterType == .path })
        XCTAssertEqual(nestedEndpoint.absolutePath[0].description, "a")
        XCTAssertEqual(nestedEndpoint.absolutePath[1].description, "b")
        XCTAssertEqual(nestedEndpoint.absolutePath[2].description, ":\(nameParameterId.uuidString)")
        XCTAssertEqual(nestedEndpoint.absolutePath[3].description, ":\(someIdParameterId.uuidString)")
    }

    private func makeRequestHandler<C: Component>(with component: C) -> RequestHandler {
        let transformer = EmojiMediator(emojis: "✅")
        let printGuard = AnyGuard(PrintGuard())
        return SharedSemanticModelBuilder.createRequestHandler(with: component,
                                                               guards: [ { printGuard } ],
                                                               responseModifiers: [ { transformer } ])
    }

    func testCreateRequestHandler() throws {
        let name = "Craig"
        let expectedResponse = "✅ Hello \(name) ✅"
        let request = RESTRequest(Vapor.Request(application: app, on: app.eventLoopGroup.next())) { _ in name }

        let response = try makeRequestHandler(with: TestHandler())(request).wait()
        // Default request handler without using Action
        // (as implemented in TestHandler)
        // should result in a value wrapped in .final Action
        if case let .final(responseEncodable) = response {
            let responseString = try XCTUnwrap(responseEncodable.value as? String)
            XCTAssert(responseString == expectedResponse)
        } else {
            XCTFail("Expected .final(\(expectedResponse), but got \(response)")
        }
    }

    func testActionPassthrough_send() throws {
        let name = "Craig"
        let expectedResponse = "✅ Hello \(name) ✅"
        let request = RESTRequest(Vapor.Request(application: app, on: app.eventLoopGroup.next())) { _ in name }
        let component = ActionHandler1().withEnvironment(Connection(state: .open), for: \.connection)

        let response = try makeRequestHandler(with: component)(request).wait()
        if case let .send(responseEncodable) = response {
            let responseString = try XCTUnwrap(responseEncodable.value as? String)
            XCTAssert(responseString == expectedResponse)
        } else {
            XCTFail("Expected .send(\(expectedResponse), but got \(response)")
        }
    }

    func testActionPassthrough_final() throws {
        let name = "Craig"
        let expectedResponse = "✅ Bye \(name) ✅"
        let request = RESTRequest(Vapor.Request(application: app, on: app.eventLoopGroup.next())) { _ in name }
        let component = ActionHandler1().withEnvironment(Connection(state: .end), for: \.connection)

        let response = try makeRequestHandler(with: component)(request).wait()
        if case let .final(responseEncodable) = response {
            let responseString = try XCTUnwrap(responseEncodable.value as? String)
            XCTAssert(responseString == expectedResponse)
        } else {
            XCTFail("Expected .final(\(expectedResponse), but got \(response)")
        }
    }

    func testActionPassthrough_nothing() throws {
        let request = RESTRequest(Vapor.Request(application: app, on: app.eventLoopGroup.next())) { _ in "" }
        let component = ActionHandler2().withEnvironment(Connection(state: .open), for: \.connection)

        let response = try makeRequestHandler(with: component)(request).wait()
        switch response {
        case .nothing:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected .nothing but got \(response)")
        }
    }

    func testActionPassthrough_end() throws {
        let request = RESTRequest(Vapor.Request(application: app, on: app.eventLoopGroup.next())) { _ in "" }
        let component = ActionHandler2().withEnvironment(Connection(state: .end), for: \.connection)

        let response = try makeRequestHandler(with: component)(request).wait()
        switch response {
        case .end:
            XCTAssert(true)
        default:
            XCTFail("Expected .end but got \(response)")
        }
    }
}
