//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTApodini
import XCTApodiniNetworking
import Apodini
import ApodiniNetworking
import ApodiniNetworkingHTTPSupport
import XCTUtils


class ApodiniNetworkingHTTPSupportTests: XCTApodiniTest {
    func testAccessControlAllowOriginHTTPResponseHeader() throws {
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
            XCTAssertEqual(response.headers, ["Access-Control-Allow-Origin": "test"])
        }
    }
    
    
    func testAccessControlAllowOriginWildcardHTTPResponseHeader() throws {
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
            XCTAssertEqual(response.headers, ["Access-Control-Allow-Origin": "*"])
        }
    }
    
    
    func testArrayBasedHeader() {
        struct CustomHeaderField: HTTPHeaderFieldValueCodable {
            let name: String
            init(name: String) { self.name = name }
            init?(httpHeaderFieldValue value: String) { name = value }
            func encodeToHTTPHeaderFieldValue() -> String { name }
        }
        
        let customFieldHeaderName = HTTPHeaderName<[CustomHeaderField]>("X-CustomField")
        
        var headers = HTTPHeaders()
        
        headers[customFieldHeaderName] = [
            .init(name: "Lukas"),
            .init(name: "Paul")
        ]
        XCTAssertEqual(headers[customFieldHeaderName], [.init(name: "Lukas"), .init(name: "Paul")])
        
        headers[customFieldHeaderName] = [
            .init(name: "Lukas,Paul")
        ]
        XCTAssertEqual(headers[customFieldHeaderName], [.init(name: "Lukas"), .init(name: "Paul")])
        
        headers[customFieldHeaderName] = [
            .init(name: "Lukas"),
            .init(name: "Paul")
        ]
        XCTAssertEqual(headers[customFieldHeaderName], [.init(name: "Lukas"), .init(name: "Paul")])
        
        headers[customFieldHeaderName].append(.init(name: "Bernd"))
        XCTAssertEqual(headers[customFieldHeaderName], [.init(name: "Lukas"), .init(name: "Paul"), .init(name: "Bernd")])
        
        headers[customFieldHeaderName].append(contentsOf: [.init(name: "Nadine"), .init(name: "Valentin")])
        XCTAssertEqual(headers[customFieldHeaderName], [.init(name: "Lukas"), .init(name: "Paul"), .init(name: "Bernd"), .init(name: "Nadine"), .init(name: "Valentin")])
    }
    
    
    func testArrayBasedHeaderSetCookie() {
        var headers = HTTPHeaders()
        
        headers[.setCookie] = [
            .init(cookieName: "My-Cookie-Name-1", cookieValue: "a"),
            .init(cookieName: "My-Cookie-Name-1", cookieValue: "b"),
            .init(cookieName: "My-Cookie-Name-2", cookieValue: "c")
        ]
        XCTAssertEqualIgnoringOrder(headers[.setCookie], [
            .init(cookieName: "My-Cookie-Name-1", cookieValue: "a"),
            .init(cookieName: "My-Cookie-Name-1", cookieValue: "b"),
            .init(cookieName: "My-Cookie-Name-2", cookieValue: "c")
        ])
        
        headers[.setCookie].append(.init(cookieName: "My-Cookie-Name-1", cookieValue: "d"))
        XCTAssertEqualIgnoringOrder(headers[.setCookie], [
            .init(cookieName: "My-Cookie-Name-1", cookieValue: "a"),
            .init(cookieName: "My-Cookie-Name-1", cookieValue: "b"),
            .init(cookieName: "My-Cookie-Name-2", cookieValue: "c"),
            .init(cookieName: "My-Cookie-Name-1", cookieValue: "d")
        ])
        
        headers[.setCookie] = [
            .init(cookieName: "My-Cookie-Name-1", cookieValue: "a"),
            .init(cookieName: "My-Cookie-Name-1", cookieValue: "b"),
            .init(cookieName: "My-Cookie-Name-2", cookieValue: "c")
        ]
        XCTAssertEqualIgnoringOrder(headers[.setCookie], [
            .init(cookieName: "My-Cookie-Name-1", cookieValue: "a"),
            .init(cookieName: "My-Cookie-Name-1", cookieValue: "b"),
            .init(cookieName: "My-Cookie-Name-2", cookieValue: "c")
        ])
        
        headers[.setCookie] = []
        XCTAssertEqual(headers[.setCookie], [])
        
        let cookieDef = SetCookieHTTPHeaderValue(
            cookieName: "My-Other-Cookie",
            cookieValue: "CookieValue",
            expires: Date.distantFuture,
            maxAge: 120,
            domain: "in.tum.de",
            path: "/alice1",
            secure: true,
            httpOnly: false,
            sameSite: .strict
        )
        headers[.setCookie] = [cookieDef]
        XCTAssertEqualIgnoringOrder(headers[.setCookie], [cookieDef])
        XCTAssertEqual(headers, [
            "Set-Cookie": "My-Other-Cookie=CookieValue; Expires=Mon, 01 Jan 4001 00:00:00 GMT; Max-Age=120; Domain=in.tum.de; Path=/alice1; Secure; SameSite=Strict"
        ])
    }
}
