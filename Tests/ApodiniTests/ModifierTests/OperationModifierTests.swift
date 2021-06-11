//
//  OperationModifierTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/2/21.
//

import XCTVapor
@testable import Apodini
@testable import ApodiniVaporSupport
@testable import ApodiniREST


final class OperationModifierTests: ApodiniTests {
    struct TestWebService: WebService {
        var version = Version(prefix: "version", major: 3, minor: 2, patch: 4)
        
        var content: some Component {
            Group("default") {
                Text("Read")
            }
            Text("Create")
                .operation(.read)
                .operation(.create)
            Group {
                Text("Update")
                    .operation(.delete)
                    .operation(.update)
                Text("Delete")
                    .operation(.delete)
                Text("Read")
                    .operation(.create)
                    .operation(.read)
            }
        }

        var configuration: Configuration {
            REST()
        }
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        TestWebService.start(app: app)
    }
    
    func testRESTOperationModifier() throws {
        struct Content: Decodable {
            let data: String
        }

        func expect(_ data: String, in response: XCTHTTPResponse) throws {
            XCTAssertEqual(response.status, .ok)
            let content = try response.content.decode(Content.self)
            XCTAssert(content.data == data)
        }
        
        try app.vapor.app.test(.GET, "/version3/default") { res in
            try expect("Read", in: res)
        }
        
        try app.vapor.app.test(.POST, "/version3/") { res in
            try expect("Create", in: res)
        }
        
        try app.vapor.app.test(.PUT, "/version3/") { res in
            try expect("Update", in: res)
        }
        
        try app.vapor.app.test(.DELETE, "/version3/") { res in
            try expect("Delete", in: res)
        }
        
        try app.vapor.app.test(.GET, "/version3/") { res in
            try expect("Read", in: res)
        }
    }
    
    func testGraphQLOperationModifier() throws {
        // Add test cases similiar to testRESTOperationModifier once the GraphQL Interface Exporter can deal with the different operations
    }
    
    func testGRPCOperationModifier() throws {
        // Add test cases similiar to testRESTOperationModifier once the GraphQL Interface Exporter can deal with the different operations
    }
    
    func testWebSocketOperationModifier() throws {
        // Add test cases similiar to testRESTOperationModifier once the GraphQL Interface Exporter can deal with the different operations
    }
    
    func testOpenAPIOperationModifier() throws {
        // Add test cases similiar to testRESTOperationModifier once the GraphQL Interface Exporter can deal with the different operations
    }
}
