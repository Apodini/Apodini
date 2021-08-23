//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
@testable import Apodini
@testable import ApodiniGRPC

final class GRPCServiceTests: ApodiniTests {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    func testWebService<S: WebService>(_ type: S.Type, path: String) throws {
        let app = Application()
        S().start(app: app)
        defer { app.shutdown() } // This might in fact not be necessary
        
        try app.vapor.app.test(.POST, path, headers: ["content-type": GRPCService.grpcproto.description]) { res in
            XCTAssertGreaterThanOrEqual(res.status.code, 200)
            XCTAssertLessThan(res.status.code, 300)
        }
    }
}

extension GRPCServiceTests {
    func testPrimitiveResponse() {
        let responseString = "Hello Moritz"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let service = GRPCService(name: "TestService", using: app, GRPC.ExporterConfiguration())
        let encodedData = service.makeResponse(responseString).body.data
        XCTAssertEqual(encodedData, Data(expectedResponseData))
    }

    func testCollectionResponse() {
        let responseString = ["Hello Moritz"]
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let service = GRPCService(name: "TestService", using: app, GRPC.ExporterConfiguration())
        let encodedData = service.makeResponse(responseString).body.data
        XCTAssertEqual(encodedData, Data(expectedResponseData))
    }

    func testComplexResponse() {
        struct ResponseWrapper: Encodable {
            var response: String
        }
        let response = ResponseWrapper(response: "Hello Moritz")
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let service = GRPCService(name: "TestService", using: app, GRPC.ExporterConfiguration())
        let encodedData = service.makeResponse(response).body.data
        XCTAssertEqual(encodedData, Data(expectedResponseData))
    }
}

extension GRPCServiceTests {
    func testWebServiceHelloWorld() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                HelloWorld()
                    .serviceName("service")
                    .rpcName("method")
            }
            
            var configuration: Configuration {
                GRPC(integerWidth: .sixtyFour)
            }
        }
        
        struct HelloWorld: Handler {
            func handle() -> String {
                "Hello, World!"
            }
        }
        
        try testWebService(WebService.self, path: "service/method")
    }
}
