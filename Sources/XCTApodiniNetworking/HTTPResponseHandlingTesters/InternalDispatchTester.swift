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


/// A HTTP request handling tester which dispatches all test requests internally, i.e. by sending them directly to the HTTP responder,
/// instead of initialising a client and sending them as actual live requests.
struct InternalDispatchTester: XCTApodiniNetworkingHTTPRequestHandlingTester {
    let eventLoopGroup: EventLoopGroup
    let httpResponder: HTTPResponder

    func performTest(
        _ request: XCTHTTPRequest,
        expectedBodyType: XCTApodiniNetworkingHTTPRequestHandlingTesterExpectedResponseBodyStorageType,
        responseStart: @escaping (HTTPResponse) throws -> Void,
        responseEnd: (HTTPResponse) throws -> Void
    ) throws {
        let httpRequest = HTTPRequest(
            method: request.method,
            url: request.url,
            headers: request.headers,
            bodyStorage: .buffer(request.body),
            eventLoop: eventLoopGroup.next()
        )
        let response = try httpResponder
            .respond(to: httpRequest)
            .makeHTTPResponse(for: httpRequest)
            .wait()
        try responseEnd(response)
    }
}

#endif // DEBUG || RELEASE_TESTING
