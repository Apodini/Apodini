//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import ApodiniNotifications
import XCTest
import XCTApodini

class APNSConfigurationTests: XCTApodiniTest {
    func testFailingConfiguration() throws {
        XCTAssertRuntimeFailure(APNSConfiguration(.pem(pemPath: ""), topic: "", environment: .sandbox).configure(self.app))
        XCTAssertFalse(app.notificationCenter.isAPNSConfigured)
    }

    func testPEMConfiguration() throws {
        let url = Bundle.module.url(forResource: "mock", withExtension: "pem")
        let path = try XCTUnwrap(url).path
        
        XCTAssertNoThrow(APNSConfiguration(.pem(pemPath: path), topic: "", environment: .sandbox).configure(app))
        XCTAssertNotNil(app.apns.configuration)
        XCTAssertEqual(app.apns.configuration?.environment, .sandbox)
        XCTAssertEqual(app.apns.configuration?.topic, "")
        XCTAssertTrue(app.notificationCenter.isAPNSConfigured)
    }
    
    func testP8Configuration() throws {
        let url = Bundle.module.url(forResource: "mock", withExtension: "p8")
        let path = try XCTUnwrap(url).path

        XCTAssertNoThrow(APNSConfiguration(.p8(path: path, keyIdentifier: "", teamIdentifier: ""), topic: "", environment: .sandbox).configure(app))
        XCTAssertNotNil(app.apns.configuration)
        XCTAssertEqual(app.apns.configuration?.environment, .sandbox)
        XCTAssertEqual(app.apns.configuration?.topic, "")
        XCTAssertTrue(app.notificationCenter.isAPNSConfigured)
    }
}
