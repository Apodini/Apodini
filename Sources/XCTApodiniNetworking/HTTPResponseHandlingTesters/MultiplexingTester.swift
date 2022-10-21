//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
#if DEBUG || RELEASE_TESTING

import Foundation
import Apodini
@_exported import ApodiniNetworking


/// A HTTP request handling tester which simply forwards all test requests to multiple other testers
struct MultiplexingTester: XCTApodiniNetworkingHTTPRequestHandlingTester {
    let testers: [XCTApodiniNetworkingHTTPRequestHandlingTester]

    func performTest(
        _ request: XCTHTTPRequest,
        expectedBodyType: XCTApodiniNetworkingHTTPRequestHandlingTesterExpectedResponseBodyStorageType,
        responseStart: @escaping (HTTPResponse) throws -> Void,
        responseEnd: (HTTPResponse) throws -> Void
    ) throws {
        for tester in testers {
            try tester.performTest(request, expectedBodyType: expectedBodyType, responseStart: responseStart, responseEnd: responseEnd)
        }
    }
}


#endif // DEBUG || RELEASE_TESTING
