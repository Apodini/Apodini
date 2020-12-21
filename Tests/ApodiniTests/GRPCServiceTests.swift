//
//  GRPCServiceTests.swift
//  
//
//  Created by Moritz Schüll on 21.12.20.
//

import XCTest
import Vapor
@testable import Apodini

final class GRPCServiceTests: XCTestCase {
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

    func testPrimitiveResponse() {
        let responseString = "Hello Moritz"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let service = GRPCService(name: "TestService", using: app)
        let encodedData = service.encodeResponse(responseString).body.data
        XCTAssertEqual(encodedData, Data(expectedResponseData))
    }

    func testCollectionResponse() {
        let responseString = ["Hello Moritz"]
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let service = GRPCService(name: "TestService", using: app)
        let encodedData = service.encodeResponse(responseString).body.data
        XCTAssertEqual(encodedData, Data(expectedResponseData))
    }

    func testComplexResponse() {
        struct ResponseWrapper: Encodable {
            var response: String
        }
        let response = ResponseWrapper(response: "Hello Moritz")
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let service = GRPCService(name: "TestService", using: app)
        let encodedData = service.encodeResponse(response).body.data
        XCTAssertEqual(encodedData, Data(expectedResponseData))
    }
}
