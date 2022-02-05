//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation
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
    
    
    func testQueryParamDecoding() throws {
        XCTAssertEqual(try URLQueryParameterValueDecoder().decode(String.self, from: "abcdef"), "abcdef")
        XCTAssertEqual(try URLQueryParameterValueDecoder().decode(Int.self, from: "1234"), 1234)
        XCTAssertEqual(try URLQueryParameterValueDecoder().decode(Int.self, from: "-1234"), -1234)
        XCTAssertEqual(try URLQueryParameterValueDecoder().decode(Double.self, from: "1234"), 1234)
        XCTAssertEqual(try URLQueryParameterValueDecoder().decode(Double.self, from: "1234.5678"), 1234.5678)
        XCTAssertEqual(try URLQueryParameterValueDecoder().decode(Double.self, from: "-1234.5678"), -1234.5678)
        XCTAssertEqual(try URLQueryParameterValueDecoder().decode(Float.self, from: "1234"), 1234)
        XCTAssertEqual(try URLQueryParameterValueDecoder().decode(Float.self, from: "1234.5678"), 1234.5678)
        XCTAssertEqual(try URLQueryParameterValueDecoder().decode(Float.self, from: "-1234.5678"), -1234.5678)
        XCTAssertThrowsError(try URLQueryParameterValueDecoder().decode(Int.self, from: "abcdef"))
        for trueBoolInput in ["true", "True", "TRUE", "yes", "Yes", "YES", "1"] {
            XCTAssertEqual(try URLQueryParameterValueDecoder().decode(Bool.self, from: trueBoolInput), true)
        }
        for falseBoolInput in ["false", "False", "FALSE", "no", "No", "NO", "0"] {
            XCTAssertEqual(try URLQueryParameterValueDecoder().decode(Bool.self, from: falseBoolInput), false)
        }
        for invalidBoolInput in ["2", "3", "4", "a", "b", "c"] { // obviously not an exhaustive list...
            XCTAssertThrowsError(try URLQueryParameterValueDecoder().decode(Bool.self, from: invalidBoolInput))
        }
    }
    
    
    func testQueryParamDateDecoding() throws {
        func imp(_ strategy: DateDecodingStrategy, input: String) throws -> Date {
            try URLQueryParameterValueDecoder(dateDecodingStrategy: strategy).decode(Date.self, from: input)
        }
        for _ in 0...1000 {
            let date = Date()
            XCTAssertEqual(try imp(.secondsSinceReferenceDate, input: "\(date.timeIntervalSinceReferenceDate)"), date)
            XCTAssertEqual(try imp(.secondsSince1970, input: "\(date.timeIntervalSince1970)").timeIntervalSince1970, date.timeIntervalSince1970)
            XCTAssertEqual(try imp(.default, input: "\(date.timeIntervalSince1970)").timeIntervalSince1970, date.timeIntervalSince1970)
        }
        XCTAssertEqual(
            try imp(.iso8601, input: "2022-01-25T15:24:25Z"),
            Calendar.current.date(from: .init(timeZone: .init(identifier: "UTC")!, year: 2022, month: 01, day: 25, hour: 15, minute: 24, second: 25))!
        )
    }
}
