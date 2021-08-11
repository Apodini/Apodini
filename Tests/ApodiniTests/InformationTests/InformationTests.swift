//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
import ApodiniHTTPProtocol
import XCTApodini


final class InformationTests: XCTestCase {
    func testMockInformation() throws {
        let information1: InformationSet = [
            MockInformation(key: "testKey", rawValue: "SomeValue"),
            MockIntInformationInstantiatable(5)
        ]

        let information2: InformationSet = [
            MockInformation(key: MockIntInformationInstantiatable.key, rawValue: "4")
        ]

        let information3: InformationSet = []

        XCTAssertEqual(information1[MockStringKey("testKey")], "SomeValue")
        XCTAssertEqual(information1[MockIntInformationInstantiatable.key], "5")
        XCTAssertEqual(information1[MockIntInformationInstantiatable.self], 5)

        XCTAssertEqual(information2[MockStringKey("testKey")], nil)
        XCTAssertEqual(information2[MockIntInformationInstantiatable.key], "4")
        XCTAssertEqual(information2[MockIntInformationInstantiatable.self], 4)

        XCTAssertEqual(information3[MockStringKey("testKey")], nil)
        XCTAssertEqual(information3[MockIntInformationInstantiatable.key], nil)
        XCTAssertEqual(information3[MockIntInformationInstantiatable.self], nil)
    }

    func testMockInformationParsing() throws {
        let input = ["testKey": "3", MockIntInformationInstantiatable.key.key: "5"]

        let information = InformationSet(input.map { key, value in
            MockInformation(key: key, rawValue: value)
        })

        XCTAssertEqual(information[MockStringKey("testKey")], "3")
        XCTAssertEqual(information[MockIntInformationInstantiatable.key], "5")
        XCTAssertEqual(information[MockIntInformationInstantiatable.self], 5)

        let result: [String: String] = information
            .compactMap { $0 as? MockStringInformationClass }
            .map { $0.entry }
            .reduce(into: [:]) { result, entry in
                result[entry.key] = entry.value
            }

        let result2: [String: String] = information
            .compactMap { $0 as? MockString2InformationClass }
            .map { $0.entry }
            .reduce(into: [:]) { result, entry in
                result[entry.key] = entry.value
            }

        let intResult: [String: Int] = information
            .compactMap { $0 as? MockIntInformationClass }
            .map { $0.entry }
            .reduce(into: [:]) { result, entry in
                result[entry.key] = entry.value
            }

        XCTAssertEqual(result["testKey"], "3")
        XCTAssertEqual(result[MockIntInformationInstantiatable.key.key], "5")

        XCTAssertEqual(result, result2)

        XCTAssertEqual(intResult["testKey"], 3)
        XCTAssertEqual(intResult[MockIntInformationInstantiatable.key.key], 5)
    }

    func testInformationParsingAuthentication() throws {
        let basicAuthorization = try XCTUnwrap(
            AnyHTTPInformation(key: "Authorization", rawValue: "Basic UGF1bFNjaG1pZWRtYXllcjpTdXBlclNlY3JldFBhc3N3b3Jk")
                .typed(Authorization.self)
        )
        XCTAssertEqual(basicAuthorization.type, "Basic")
        XCTAssertEqual(basicAuthorization.credentials, "UGF1bFNjaG1pZWRtYXllcjpTdXBlclNlY3JldFBhc3N3b3Jk")
        XCTAssertEqual(basicAuthorization.basic?.username, "PaulSchmiedmayer")
        XCTAssertEqual(basicAuthorization.basic?.password, "SuperSecretPassword")
        XCTAssertNil(basicAuthorization.bearerToken)
        
        
        let bearerAuthorization = try XCTUnwrap(
            AnyHTTPInformation(key: "Authorization", rawValue: "Bearer QWEERTYUIOPASDFGHJKLZXCVBNM")
                .typed(Authorization.self)
        )
        
        XCTAssertEqual(bearerAuthorization.type, "Bearer")
        XCTAssertEqual(bearerAuthorization.credentials, "QWEERTYUIOPASDFGHJKLZXCVBNM")
        XCTAssertEqual(bearerAuthorization.bearerToken, "QWEERTYUIOPASDFGHJKLZXCVBNM")
        XCTAssertNil(bearerAuthorization.basic)
    }
    
    func testInformationParsingCookies() throws {
        let noCookies = try XCTUnwrap(
            AnyHTTPInformation(key: "Cookie", rawValue: "")
                .typed(Cookies.self)
        )
        XCTAssertTrue(noCookies.isEmpty)
        
        let noValidCookies = try XCTUnwrap(
            AnyHTTPInformation(key: "Cookie", rawValue: "test=")
                .typed(Cookies.self)
        )
        XCTAssertTrue(noValidCookies.isEmpty)
        
        let oneCookie = try XCTUnwrap(
            AnyHTTPInformation(key: "Cookie", rawValue: "name=value")
                .typed(Cookies.self)
        )
        XCTAssertEqual(oneCookie.count, 1)
        XCTAssertEqual(oneCookie["name"], "value")
        
        let cookies = try XCTUnwrap(
            AnyHTTPInformation(key: "Cookie", rawValue: "name=value; name2=value2; name3=value3")
                .typed(Cookies.self)
        )
        XCTAssertEqual(cookies.count, 3)
        XCTAssertEqual(cookies["name"], "value")
        XCTAssertEqual(cookies["name2"], "value2")
        XCTAssertEqual(cookies["name3"], "value3")
    }

    func testInformationMergingCookies() throws {
        let cookiesBase = Cookies(["name": "value", "name3": "value3"])
        let cookiesOverride = Cookies(["name2": "value2", "name3": "value3,3"])

        let set0 = InformationSet([cookiesBase])

        let resultSet = set0.merge(with: [cookiesOverride])
        let result = try XCTUnwrap(resultSet[Cookies.self])

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result["name"], "value")
        XCTAssertEqual(result["name2"], "value2")
        XCTAssertEqual(result["name3"], "value3,3")
    }
    
    func testInformationParsingETag() throws {
        let weakETag = try XCTUnwrap(
            AnyHTTPInformation(key: "ETag", rawValue: "W/\"ABCDE\"")
                .typed(ETag.self)
        )
        XCTAssertTrue(weakETag.isWeak)
        XCTAssertEqual(weakETag.tag, "ABCDE")
        
        let eTag = try XCTUnwrap(
            AnyHTTPInformation(key: "ETag", rawValue: "\"ABCDE\"")
                .typed(ETag.self)
        )
        XCTAssertFalse(eTag.isWeak)
        XCTAssertEqual(eTag.tag, "ABCDE")
        
        
        XCTAssertNil(
            AnyHTTPInformation(key: "ETag", rawValue: "")
                .typed(ETag.self)
        )
    }
    
    func testInformationParsingExpires() throws {
        let expires = try XCTUnwrap(
            AnyHTTPInformation(key: "Expires", rawValue: "Wed, 16 June 2021 11:42:00 GMT")
                .typed(Expires.self)
        )
        XCTAssertEqual(expires.value, Date(timeIntervalSince1970: 1623843720))
        
        
        XCTAssertNil(
            AnyHTTPInformation(key: "Expires", rawValue: "...")
                .typed(Expires.self)
        )
    }
    
    func testInformationParsingRedirectTo() throws {
        let redirectTo = try XCTUnwrap(
            AnyHTTPInformation(key: "Location", rawValue: "https://ase.in.tum.de/schmiedmayer")
                .typed(RedirectTo.self)
        )
        XCTAssertEqual(redirectTo.value.absoluteString, "https://ase.in.tum.de/schmiedmayer")
    }

    func testInformationMergingWWWAuthenticate() throws {
        let basic = WWWAuthenticate(.init(scheme: "Basic", parameters: .init(key: "realm", value: "My \"Test\" Realm")))
        let bearer = WWWAuthenticate(.init(scheme: "Bearer", parameters: .init(key: "realm", value: "MyTestRealm")))
        let bearerWithError = WWWAuthenticate(.init(scheme: "Bearer", parameters: .init(key: "error", value: "invalid_request")))

        var set = InformationSet([basic])

        set = set.merge(with: [bearer])

        XCTAssertEqual(
            try XCTUnwrap(set[httpHeader: WWWAuthenticate.header]),
            "Basic realm=\"My \\\"Test\\\" Realm\", Bearer realm=MyTestRealm"
        )

        set = set.merge(with: [bearerWithError])

        XCTAssertEqual(
            try XCTUnwrap(set[httpHeader: WWWAuthenticate.header]),
            "Basic realm=\"My \\\"Test\\\" Realm\", Bearer error=invalid_request"
        )
    }
}
