//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import XCTest
@testable import ApodiniNetworking


class ApodiniNetworkingTests: XCTestCase {
    func testHTTPPathComponentParsing() {
        func test(_ string: String, _ expectedResult: [HTTPPathComponent]) {
            let value: [HTTPPathComponent] = .init(string)
            XCTAssertEqual(value, expectedResult)
        }
        test("", [])
        test("/", [])
        test("/v1", [.verbatim("v1")])
        test("/v1/greet", [.verbatim("v1"), .verbatim("greet")])
        test("/v1/greet/", [.verbatim("v1"), .verbatim("greet")])
        test("/v1/greet/:name", [.verbatim("v1"), .verbatim("greet"), .namedParameter("name")])
        test("/v1/greet/*", [.verbatim("v1"), .verbatim("greet"), .wildcardSingle(nil)])
        test("/v1/greet/**", [.verbatim("v1"), .verbatim("greet"), .wildcardMultiple(nil)])
    }
    
    func testHTTPPathComponentsFormatting() {
        func test(_ input: [HTTPPathComponent], httpPathString: String, effectivePath: String) {
            XCTAssertEqual(input.httpPathString, httpPathString)
            XCTAssertEqual(input.effectivePath, effectivePath)
        }
        test([], httpPathString: "/", effectivePath: "/")
        test(
            [.verbatim("v1")],
            httpPathString: "/v1",
            effectivePath: "/v[v1]"
        )
        test(
            [.verbatim("v1"), .verbatim("greet")],
            httpPathString: "/v1/greet",
            effectivePath: "/v[v1]/v[greet]"
        )
        test(
            [.verbatim("v1"), .verbatim("greet"), .namedParameter("name")],
            httpPathString: "/v1/greet/:name",
            effectivePath: "/v[v1]/v[greet]/:"
        )
        test(
            [.verbatim("v1"), .verbatim("greet"), .wildcardSingle(nil)],
            httpPathString: "/v1/greet/*",
            effectivePath: "/v[v1]/v[greet]/*"
        )
        test(
            [.verbatim("v1"), .verbatim("greet"), .wildcardSingle("wc")],
            httpPathString: "/v1/greet/*[wc]",
            effectivePath: "/v[v1]/v[greet]/*[wc]"
        )
        test(
            [.verbatim("v1"), .verbatim("greet"), .wildcardMultiple(nil)],
            httpPathString: "/v1/greet/**",
            effectivePath: "/v[v1]/v[greet]/**"
        )
        test(
            [.verbatim("v1"), .verbatim("greet"), .wildcardMultiple("wm")],
            httpPathString: "/v1/greet/**[wm]",
            effectivePath: "/v[v1]/v[greet]/**[wm]"
        )
    }
}
