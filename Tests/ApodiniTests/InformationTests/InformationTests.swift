//
//  InformationTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

@testable import Apodini
import XCTApodini


final class InformationTests: XCTestCase {
    func testInformationParsingAuthentication() throws {
        let basicAuthorization = try XCTUnwrap(
            AnyInformation(key: "Authorization", rawValue: "Basic UGF1bFNjaG1pZWRtYXllcjpTdXBlclNlY3JldFBhc3N3b3Jk")
                .typed(Authorization.self)
        )
        XCTAssertEqual(basicAuthorization.type, "Basic")
        XCTAssertEqual(basicAuthorization.credentials, "UGF1bFNjaG1pZWRtYXllcjpTdXBlclNlY3JldFBhc3N3b3Jk")
        XCTAssertEqual(basicAuthorization.basic?.username, "PaulSchmiedmayer")
        XCTAssertEqual(basicAuthorization.basic?.password, "SuperSecretPassword")
        XCTAssertNil(basicAuthorization.bearerToken)
        
        
        let bearerAuthorization = try XCTUnwrap(
            AnyInformation(key: "Authorization", rawValue: "Bearer QWEERTYUIOPASDFGHJKLZXCVBNM")
                .typed(Authorization.self)
        )
        
        XCTAssertEqual(bearerAuthorization.type, "Bearer")
        XCTAssertEqual(bearerAuthorization.credentials, "QWEERTYUIOPASDFGHJKLZXCVBNM")
        XCTAssertEqual(bearerAuthorization.bearerToken, "QWEERTYUIOPASDFGHJKLZXCVBNM")
        XCTAssertNil(bearerAuthorization.basic)
    }
    
    func testInformationParsingCookies() throws {
        let noCookies = try XCTUnwrap(
            AnyInformation(key: "Cookie", rawValue: "")
                .typed(Cookies.self)
        )
        XCTAssertTrue(noCookies.isEmpty)
        
        let noValidCookies = try XCTUnwrap(
            AnyInformation(key: "Cookie", rawValue: "test=")
                .typed(Cookies.self)
        )
        XCTAssertTrue(noValidCookies.isEmpty)
        
        let oneCookie = try XCTUnwrap(
            AnyInformation(key: "Cookie", rawValue: "name=value")
                .typed(Cookies.self)
        )
        XCTAssertEqual(oneCookie.count, 1)
        XCTAssertEqual(oneCookie["name"], "value")
        
        let cookies = try XCTUnwrap(
            AnyInformation(key: "Cookie", rawValue: "name=value; name2=value2; name3=value3")
                .typed(Cookies.self)
        )
        XCTAssertEqual(cookies.count, 3)
        XCTAssertEqual(cookies["name"], "value")
        XCTAssertEqual(cookies["name2"], "value2")
        XCTAssertEqual(cookies["name3"], "value3")
    }
    
    func testInformationParsingETag() throws {
        let weakETag = try XCTUnwrap(
            AnyInformation(key: "ETag", rawValue: "W/\"ABCDE\"")
                .typed(ETag.self)
        )
        XCTAssertTrue(weakETag.isWeak)
        XCTAssertEqual(weakETag.tag, "ABCDE")
        
        let eTag = try XCTUnwrap(
            AnyInformation(key: "ETag", rawValue: "\"ABCDE\"")
                .typed(ETag.self)
        )
        XCTAssertFalse(eTag.isWeak)
        XCTAssertEqual(eTag.tag, "ABCDE")
        
        
        XCTAssertNil(
            AnyInformation(key: "ETag", rawValue: "")
                .typed(ETag.self)
        )
    }
    
    func testInformationParsingExpires() throws {
        let expires = try XCTUnwrap(
            AnyInformation(key: "Expires", rawValue: "Wed, 16 June 2021 11:42:00 GMT")
                .typed(Expires.self)
        )
        XCTAssertEqual(expires.value, Date(timeIntervalSince1970: 1623843720))
        
        
        XCTAssertNil(
            AnyInformation(key: "Expires", rawValue: "...")
                .typed(Expires.self)
        )
    }
    
    func testInformationParsingRedirectTo() throws {
        let redirectTo = try XCTUnwrap(
            AnyInformation(key: "Location", rawValue: "https://ase.in.tum.de/schmiedmayer")
                .typed(RedirectTo.self)
        )
        XCTAssertEqual(redirectTo.value.absoluteString, "https://ase.in.tum.de/schmiedmayer")
    }
}
