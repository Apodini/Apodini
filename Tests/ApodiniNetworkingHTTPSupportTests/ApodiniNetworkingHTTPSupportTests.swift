//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTApodiniNetworking
import Apodini
import ApodiniNetworking
import ApodiniNetworkingHTTPSupport

class ApodiniNetworkingHTTPSupportTests: XCTestCase {
    func testAccessControlAllowOriginHTTPResponseHeader() throws {
        let app = Application()
        
        try app.httpServer.registerRoute(.GET, "test") { req in
            HTTPResponse(
                version: req.version,
                status: .ok,
                headers: HTTPHeaders {
                    $0[.accessControlAllowOrigin] = .origin("test")
                }
            )
        }
        
        XCTAssertEqual(AccessControlAllowOriginHeaderValue(httpHeaderFieldValue: "test"), .origin("test"))
        
        try app.testable().test(.GET, "test") { response in
            XCTAssertEqual(response.headers, HTTPHeaders(dictionaryLiteral: ("Access-Control-Allow-Origin", "test")))
        }
    }
    
    func testAccessControlAllowOriginWildcardHTTPResponseHeader() throws {
        let app = Application()
        
        try app.httpServer.registerRoute(.GET, "test") { req in
            HTTPResponse(
                version: req.version,
                status: .ok,
                headers: HTTPHeaders {
                    $0[.accessControlAllowOrigin] = .wildcard
                }
            )
        }
        
        XCTAssertEqual(AccessControlAllowOriginHeaderValue(httpHeaderFieldValue: "*"), .wildcard)
        
        try app.testable().test(.GET, "test") { response in
            XCTAssertEqual(response.headers, HTTPHeaders(dictionaryLiteral: ("Access-Control-Allow-Origin", "*")))
        }
    }
}
