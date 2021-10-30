//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
import XCTest

final class WebserviceTests: XCTestCase {
    func testMain() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Text("42")
            }

            var configuration: Configuration {
                HTTPConfiguration()
            }
        }

        let app = try TestWebService.start(mode: .boot)
        app.shutdown()
    }
}
