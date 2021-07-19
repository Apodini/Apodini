//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import XCTApodini
@testable import ApodiniNotifications

class FCMConfigurationTests: XCTApodiniTest {
    func testMissingFile() throws {
        XCTAssertRuntimeFailure(FirebaseConfiguration(URL(fileURLWithPath: "")), "FCM file doesn't exist at path: something")
        XCTAssertFalse(app.notificationCenter.isFCMConfigured)
    }
    
    func testMissingProperties() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "mock_invalid_fcm", withExtension: "json"))
        
        XCTAssertRuntimeFailure(FirebaseConfiguration(url), "FCM unable to decode serviceAccount from file located at: \(url)")
        XCTAssertFalse(app.notificationCenter.isFCMConfigured)
    }
    
    func testValidFile() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "mock_fcm", withExtension: "json"))
        
        let configuration = FirebaseConfiguration(url)
        #if !os(macOS) || Xcode
        XCTAssertNoThrow(configuration.configure(self.app))
        XCTAssertNotNil(app.fcm.configuration)
        XCTAssertTrue(app.notificationCenter.isFCMConfigured)
        #else
        print("We can not test the loaded configuration \(configuration) due to the following bug when runing it from the macOS command line: https://github.com/vapor/jwt-kit/issues/26")
        #endif
    }
}
