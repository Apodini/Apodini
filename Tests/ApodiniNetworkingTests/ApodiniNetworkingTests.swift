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
        test("/v1", [.constant("v1")])
        test("/v1/greet", [.constant("v1"), .constant("greet")])
        test("/v1/greet/", [.constant("v1"), .constant("greet")])
        test("/v1/greet/:name", [.constant("v1"), .constant("greet"), .namedParameter("name")])
        test("/v1/greet/*", [.constant("v1"), .constant("greet"), .wildcardSingle(nil)])
        test("/v1/greet/**", [.constant("v1"), .constant("greet"), .wildcardMultiple(nil)])
    }
    
    func testHTTPPathComponentsFormatting() {
        func test(_ input: [HTTPPathComponent], httpPathString: String, effectivePath: String) {
            XCTAssertEqual(input.httpPathString, httpPathString)
            XCTAssertEqual(input.effectivePath, effectivePath)
        }
        test([], httpPathString: "/", effectivePath: "/")
        test(
            [.constant("v1")],
            httpPathString: "/v1",
            effectivePath: "/v[v1]"
        )
        test(
            [.constant("v1"), .constant("greet")],
            httpPathString: "/v1/greet",
            effectivePath: "/v[v1]/v[greet]"
        )
        test(
            [.constant("v1"), .constant("greet"), .namedParameter("name")],
            httpPathString: "/v1/greet/:name",
            effectivePath: "/v[v1]/v[greet]/:"
        )
        test(
            [.constant("v1"), .constant("greet"), .wildcardSingle(nil)],
            httpPathString: "/v1/greet/*",
            effectivePath: "/v[v1]/v[greet]/*"
        )
        test(
            [.constant("v1"), .constant("greet"), .wildcardSingle("wc")],
            httpPathString: "/v1/greet/*[wc]",
            effectivePath: "/v[v1]/v[greet]/*[wc]"
        )
        test(
            [.constant("v1"), .constant("greet"), .wildcardMultiple(nil)],
            httpPathString: "/v1/greet/**",
            effectivePath: "/v[v1]/v[greet]/**"
        )
        test(
            [.constant("v1"), .constant("greet"), .wildcardMultiple("wm")],
            httpPathString: "/v1/greet/**[wm]",
            effectivePath: "/v[v1]/v[greet]/**[wm]"
        )
    }
}
