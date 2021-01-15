//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-29.
//

import Foundation
import XCTest
@testable import Apodini


final class HandlerIdentifierTests: ApodiniTests {
    // Hashable summary of an endpoint, useful for comparing endpoint arrays
    private struct EndpointSummary: Hashable {
        let id: String
        let path: String
        let description: String

        init(id: String, path: String, description: String) {
            self.id = id
            self.path = path
            self.description = description
        }

        init(endpoint: AnyEndpoint) {
            self.init(
                id: endpoint.identifier.rawValue,
                path: endpoint.absolutePath.asPathString(),
                description: endpoint.description
            )
        }
    }


    struct TestHandlerType: IdentifiableHandler {
        typealias Response = Never
        let handlerId = ScopedHandlerIdentifier<Self>("main")
    }
    
    
    func testScopedHandlerIdentifier() {
        XCTAssertEqual(TestHandlerType().handlerId, AnyHandlerIdentifier("TestHandlerType.main"))
    }
    

    func testDefaultHandlerIdentifier() {
        struct TestWebService: WebService {
            var content: some Component {
                Group("x") {
                    Text("a")
                }
                Group("x/y") {
                    Text("b")
                }
            }
        }
        
        let builder = SharedSemanticModelBuilder(app)
        TestWebService().register(builder)
        
        let actualEndpoints: [EndpointSummary] = builder.rootNode.collectAllEndpoints().map(EndpointSummary.init)
        
        let expectedEndpoints: [EndpointSummary] = [
            EndpointSummary(id: "0:0:0", path: "/v1/x", description: String(describing: type(of: Text("a")))),
            EndpointSummary(id: "0:1:0", path: "/v1/x/y", description: String(describing: type(of: Text("b"))))
        ]
        
        XCTAssert(actualEndpoints.compareIgnoringOrder(expectedEndpoints), "Expected: \(expectedEndpoints). Actual: \(actualEndpoints)")
    }


    func testDefaultHandlerIdentifier2() {
        struct TestWebService: WebService {
            var content: some Component {
                Text("a")
                Text("b")
                    .operation(.create)
                Group("x") {
                    Text("c")
                }
                Group("x/y") {
                    Text("d")
                }
            }
        }
        
        let builder = SharedSemanticModelBuilder(app)
        TestWebService().register(builder)
        
        let actualEndpoints: [EndpointSummary] = builder.rootNode.collectAllEndpoints().map(EndpointSummary.init)
        
        let expectedEndpoints: [EndpointSummary] = [
            EndpointSummary(id: "0:0", path: "/v1", description: String(describing: type(of: Text("a")))),
            EndpointSummary(id: "0:1", path: "/v1", description: String(describing: type(of: Text("b")))),
            EndpointSummary(id: "0:2:0", path: "/v1/x", description: String(describing: type(of: Text("c")))),
            EndpointSummary(id: "0:3:0", path: "/v1/x/y", description: String(describing: type(of: Text("d"))))
        ]
        
        XCTAssert(actualEndpoints.compareIgnoringOrder(expectedEndpoints), "Expected: \(expectedEndpoints). Actual: \(actualEndpoints)")
    }


    func testDefaultHandlerIdentifier3() {
        struct TestWebService: WebService {
            var content: some Component {
                Group("x/y") {
                    Group("z") {
                        Text("a")
                    }
                }
                Text("b")
            }
        }
        
        let builder = SharedSemanticModelBuilder(app)
        TestWebService().register(builder)
        
        let actualEndpoints: [EndpointSummary] = builder.rootNode.collectAllEndpoints().map(EndpointSummary.init)
        
        let expectedEndpoints: [EndpointSummary] = [
            EndpointSummary(id: "0:0:0:0", path: "/v1/x/y/z", description: String(describing: type(of: Text("a")))),
            EndpointSummary(id: "0:1", path: "/v1", description: String(describing: type(of: Text("b"))))
        ]
        
        XCTAssert(actualEndpoints.compareIgnoringOrder(expectedEndpoints), "Expected: \(expectedEndpoints). Actual: \(actualEndpoints)")
    }


    func testHandlerIdentifierCreationUsingREST() throws {
        struct TestHandler: IdentifiableHandler {
            func handle() -> String {
                handlerId.description
            }
            
            var handlerId: some AnyHandlerIdentifier {
                AnyHandlerIdentifier(Self.self)
            }
        }
        
        struct TestWebService: WebService {
            var content: some Component {
                TestHandler()
            }
        }
        
        TestWebService.main(app: app)
        
        
        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == AnyHandlerIdentifier(TestHandler.self).description)
        }
    }
}
