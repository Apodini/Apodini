//
//  InformationResponseTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Foundation
import XCTApodini
import ApodiniREST


final class InformationResponseTests: XCTApodiniTest {
    func testInformationResponse() throws {
        let expectedAuthorization = Authorization(.basic(username: "PaulSchmiedmayer", password: "SuperSecretPassword"))

        let response: Response = .send(42, status: .ok, information: [
            expectedAuthorization,
            Cookies(["test": "value"]),
            ETag("ABCD", isWeak: true),
            Expires(Date(timeIntervalSince1970: 1623843720)),
            RedirectTo(try XCTUnwrap(URL(string: "https://ase.in.tum.de/schmiedmayer"))),
            AnyHTTPInformation(key: "Test", rawValue: "ATest")
        ])
        
        XCTAssertEqual(response.information.count, 6)
        
        let authorization = try XCTUnwrap(response.information[Authorization.self])
        XCTAssertEqual(authorization.basic?.username, "PaulSchmiedmayer")
        XCTAssertEqual(authorization.basic?.password, "SuperSecretPassword")

        let anyAuthorization = try XCTUnwrap(response.information[httpHeader: Authorization.header])
        XCTAssertEqual(anyAuthorization, expectedAuthorization.rawValue)
    }
    
    func testInformationResponseOverlaping() throws {
        let response: Response = .send(42, status: .ok, information: [
            Authorization(.bearer("QWEERTYUIOPASDFGHJKLZXCVBNM")),
            AnyHTTPInformation(key: "Authorization", rawValue: "Test Test"),
            AnyHTTPInformation(key: "Test", rawValue: "ATest"),
            AnyHTTPInformation(key: "Test", rawValue: "ASecondTest")
        ])
        
        XCTAssertEqual(response.information.count, 2)
    }
}
