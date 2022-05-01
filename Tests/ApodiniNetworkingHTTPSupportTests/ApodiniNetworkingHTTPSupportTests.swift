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
    func testHeaderCoding() {
        // We need this as a struct in order to get the Hashable conformnace; tuples can't do that yet...
        struct HeaderEntry: Hashable {
            let name: String
            let value: String
        }
        
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let headers = HTTPHeaders {
            $0[.authorityPseudoHeader] = "in.tum.de"
            $0[.pathPseudoHeader] = "/alice1"
            $0[.statusPseudoHeader] = .ok
            $0[.authorization] = .bearer(token: "TOKEN")
            $0[.date] = date
            $0[.server] = "Apodini"
            $0[.accept] = [.json]
            $0[.transferEncoding] = [.gzip]
            $0[.contentType] = .xml
            $0[.contentEncoding] = [.compress, .gzip]
            $0[.setCookie] = [
                .init(
                    cookieName: "X-Name",
                    cookieValue: "Lukas",
                    expires: date,
                    maxAge: 52,
                    domain: "in.tum.de",
                    path: "/alice1",
                    secure: true,
                    httpOnly: true,
                    sameSite: .lax
                )
            ]
            $0[.accessControlAllowOrigin] = .wildcard
            $0[.connection] = [.keepAlive, .other(.upgrade)]
            $0[.upgrade] = [.http2]
            $0[.contentLength] = 100
            $0[.eTag] = .weak("ref")
            $0[.methodPseudoHeader] = .HEAD
            $0[.schemePseudoHeader] = .https
        }
        let rawHeaderEntries: [HeaderEntry] = [
            .init(name: ":authority", value: "in.tum.de"),
            .init(name: ":path", value: "/alice1"),
            .init(name: ":status", value: "200"),
            .init(name: ":method", value: "HEAD"),
            .init(name: ":scheme", value: "https"),
            .init(name: "Authorization", value: "Bearer TOKEN"),
            .init(name: "Date", value: "Mon, 01 Jan 2001 00:00:00 GMT"),
            .init(name: "Server", value: "Apodini"),
            .init(name: "Accept", value: "application/json; charset=utf-8"),
            .init(name: "Transfer-Encoding", value: "gzip"),
            .init(name: "Content-Type", value: "application/xml; charset=utf-8"),
            .init(name: "Content-Encoding", value: "compress, gzip"),
            .init(
                name: "Set-Cookie",
                value: "X-Name=Lukas; Expires=Mon, 01 Jan 2001 00:00:00 GMT; Max-Age=52; Domain=in.tum.de; Path=/alice1; Secure; HttpOnly; SameSite=Lax"
            ),
            .init(name: "Access-Control-Allow-Origin", value: "*"),
            .init(name: "Connection", value: "Keep-Alive, Upgrade"),
            .init(name: "Upgrade", value: "HTTP/2.0"),
            .init(name: "Content-Length", value: "100"),
            .init(name: "ETag", value: "W/ref")
        ]
        XCTAssertEqualIgnoringOrder(headers.map { HeaderEntry(name: $0, value: $1) }, rawHeaderEntries)
        
        XCTAssertEqual(HTTPHeaders(rawHeaderEntries.map { ($0.name, $0.value) }), headers)
        
        XCTAssertEqual(headers[.authorityPseudoHeader], "in.tum.de")
        XCTAssertEqual(headers[.pathPseudoHeader], "/alice1")
        XCTAssertEqual(headers[.statusPseudoHeader], .ok)
        XCTAssertEqual(headers[.authorization], .bearer(token: "TOKEN"))
        XCTAssertEqual(headers[.date], date)
        XCTAssertEqual(headers[.server], "Apodini")
        XCTAssertEqual(headers[.accept], [.json])
        XCTAssertEqual(headers[.transferEncoding], [.gzip])
        XCTAssertEqual(headers[.contentType], .xml)
        XCTAssertEqual(headers[.contentEncoding], [.compress, .gzip])
        XCTAssertEqual(headers[.setCookie], [
            .init(
                cookieName: "X-Name",
                cookieValue: "Lukas",
                expires: date,
                maxAge: 52,
                domain: "in.tum.de",
                path: "/alice1",
                secure: true,
                httpOnly: true,
                sameSite: .lax
            )
        ])
        XCTAssertEqual(headers[.accessControlAllowOrigin], .wildcard)
        XCTAssertEqual(headers[.connection], [.keepAlive, .other(.upgrade)])
        XCTAssertEqual(headers[.upgrade], [.http2])
        XCTAssertEqual(headers[.contentLength], 100)
        XCTAssertEqual(headers[.eTag], .weak("ref"))
        XCTAssertEqual(headers[.methodPseudoHeader], .HEAD)
        XCTAssertEqual(headers[.schemePseudoHeader], .https)
    }
    
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
        XCTAssertEqual(headers[customFieldHeaderName], [
            .init(name: "Lukas"),
            .init(name: "Paul"),
            .init(name: "Bernd"),
            .init(name: "Nadine"),
            .init(name: "Valentin")
        ])
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
            "Set-Cookie": "My-Other-Cookie=CookieValue; Expires=Mon, 01 Jan 4001 00:00:00 GMT; Max-Age=120; Domain=in.tum.de; Path=/alice1; Secure; SameSite=Strict" // swiftlint:disable:this line_length
        ])
    }
}
