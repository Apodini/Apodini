//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTApodini


final class InformationResponseTests: XCTApodiniTest {
    func testInformationResponse() throws {
        let response: Response = .send(42, status: .ok, information: [
            .authorization(.basic(username: "PaulSchmiedmayer", password: "SuperSecretPassword")),
            .cookies(["test": "value"]),
            .etag("ABCD", isWeak: true),
            .expires(Date(timeIntervalSince1970: 1623843720)),
            .redirectTo(try XCTUnwrap(URL(string: "https://ase.in.tum.de/schmiedmayer"))),
            .custom(key: "Test", rawValue: "ATest")
        ])
        
        XCTAssertEqual(response.information.count, 6)
        
        let authorization = try XCTUnwrap(response.information[Authorization.self])
        XCTAssertEqual(authorization.basic?.username, "PaulSchmiedmayer")
        XCTAssertEqual(authorization.basic?.password, "SuperSecretPassword")
    }
    
    func testInformationResponseOverlaping() throws {
        let response: Response = .send(42, status: .ok, information: [
            .authorization(.bearer("QWEERTYUIOPASDFGHJKLZXCVBNM")),
            .custom(key: "Authorization", rawValue: "Test Test"),
            .custom(key: "Test", rawValue: "ATest"),
            .custom(key: "Test", rawValue: "ASecondTest")
        ])
        
        XCTAssertEqual(response.information.count, 2)
    }
}
