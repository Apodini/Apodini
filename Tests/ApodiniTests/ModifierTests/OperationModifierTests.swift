//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
@testable import Apodini
@testable import ApodiniREST
import XCTApodiniNetworking


final class OperationModifierTests: ApodiniTests {
    struct HelloWorldHandler: Handler {
        func handle() -> String {
            "Hello World"
        }

        var metadata: Metadata {
            Operation(.delete)
        }
    }

    struct TestWebService: WebService {
        var content: some Component {
            Group("default") {
                Text("Read")
                HelloWorldHandler()
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

        var metadata: Metadata {
            Version(prefix: "version", major: 3, minor: 2, patch: 4)
        }

        var configuration: Configuration {
            REST(rootPath: .version)
        }
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        try TestWebService().start(app: app)
    }
    
    func testRESTOperationModifier() throws {
        struct Content: Decodable {
            let data: String
        }

        func expect(_ data: String, in response: HTTPResponse) throws {
            XCTAssertEqual(response.status, .ok)
            let content = try response.bodyStorage.getFullBodyData(decodedAs: Content.self)
            XCTAssert(content.data == data)
        }
        
        try app.testable().test(.GET, "/version3/default") { res in
            try expect("Read", in: res)
        }

        try app.testable().test(.DELETE, "/version3/default") { res in
            try expect("Hello World", in: res)
        }
        
        try app.testable().test(.POST, "/version3/") { res in
            try expect("Create", in: res)
        }
        
        try app.testable().test(.PUT, "/version3/") { res in
            try expect("Update", in: res)
        }
        
        try app.testable().test(.DELETE, "/version3/") { res in
            try expect("Delete", in: res)
        }
        
        try app.testable().test(.GET, "/version3/") { res in
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
