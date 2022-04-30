//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

#if DEBUG || RELEASE_TESTING

import Foundation
import XCTest
import Apodini
@_exported import ApodiniNetworking


/// How a `HTTPResponder` should be sent the test requests,
/// i.e. whether they should be dispatched internally (this is usually preferable since it results in fewer networking overhead and significantly faster tests),
/// or whether they should be sent as actual live HTTP requests over a socket (this requires, for each request, the HTTP server be started and stopped and a client be started and stopped,
/// which will result in noticably slower performance)
public enum XCTApodiniHTTPResponderTestingMethod: Hashable {
    case internalDispatch
    case actualRequests(interface: String?, port: Int?)
    
    public static var actualRequests: Self {
        .actualRequests(interface: nil, port: nil)
    }
}


/// How a tester --- absent of any further information --- should treat the expected body of a response.
public enum XCTApodiniNetworkingHTTPRequestHandlingTesterExpectedResponseBodyStorageType { // swiftlint:disable:this type_name
    /// buffer
    case buffer
    /// stream
    case stream
}



/// A type which can be sent test HTTP requests
public protocol XCTApodiniNetworkingRequestResponseTestable {
    func testable(_ methods: Set<XCTApodiniHTTPResponderTestingMethod>) -> XCTApodiniNetworkingHTTPRequestHandlingTester
}


/// A proxy that can handle testing requests
public protocol XCTApodiniNetworkingHTTPRequestHandlingTester {
    /// Perform a test
    /// - parameter request: The request to be tested
    /// - parameter expectedBodyType: Whether the response will be buffer- or stream-based
    /// - parameter responseStart: Block that will be invoked when the response starts (useful when dealing with stream-based responses). May be called on a different thread than this function's caller's
    /// - parameter responseEnd: Block that will be invoked when the response has ended. This is what should be used to perform tests etc against the response
    /// - Note: This function is synchronous, meaning that it will only return once the response has been fully received and the `responseEnd` block has returned
    func performTest(
        _ request: XCTHTTPRequest,
        expectedBodyType: XCTApodiniNetworkingHTTPRequestHandlingTesterExpectedResponseBodyStorageType,
        responseStart: @escaping (HTTPResponse) throws -> Void,
        responseEnd: (HTTPResponse) throws -> Void
    ) throws
}


private func makeUrl(version: HTTPVersion, path: String) -> URI {
    URI(string: "\(version.major > 1 ? "https" : "http")://127.0.0.1:8000/\(path.hasPrefix("/") ? path.dropFirst() : path[...])")!
}


extension XCTApodiniNetworkingHTTPRequestHandlingTester {
    /// Initiates a test request
    public func test(
        version: HTTPVersion = .http1_1,
        _ method: HTTPMethod,
        _ path: String,
        headers: HTTPHeaders = [:],
        body: ByteBuffer = .init(),
        expectedBodyType: XCTApodiniNetworkingHTTPRequestHandlingTesterExpectedResponseBodyStorageType = .buffer,
        file: StaticString = #file,
        line: UInt = #line,
        responseStart: @escaping (HTTPResponse) throws -> Void = { _ in },
        responseEnd: (HTTPResponse) throws -> Void
    ) throws {
        do {
            try self.performTest(
                XCTHTTPRequest(
                    version: version,
                    method: method,
                    url: makeUrl(version: version, path: path),
                    headers: headers,
                    body: body,
                    file: file,
                    line: line
                ),
                expectedBodyType: expectedBodyType,
                responseStart: responseStart,
                responseEnd: responseEnd
            )
        } catch {
            XCTFail("\(error)", file: file, line: line)
            throw error
        }
    }
}



// MARK: Tester conformances

extension HTTPServer: XCTApodiniNetworkingRequestResponseTestable {
    public func testable(_ methods: Set<XCTApodiniHTTPResponderTestingMethod> = [.internalDispatch]) -> XCTApodiniNetworkingHTTPRequestHandlingTester {
        MultiplexingTester(testers: methods.map { method in
            switch method {
            case .internalDispatch:
                return InternalDispatchTester(eventLoopGroup: self.eventLoopGroup, httpResponder: self)
            case let .actualRequests(interface, port):
                return ActualRequestsTester(httpServer: self, interface: interface, port: port)
            }
        })
    }
}


extension Apodini.Application: XCTApodiniNetworkingRequestResponseTestable {
    public func testable(_ methods: Set<XCTApodiniHTTPResponderTestingMethod> = [.internalDispatch]) -> XCTApodiniNetworkingHTTPRequestHandlingTester {
        httpServer.testable(methods)
    }
}

#endif // DEBUG || RELEASE_TESTING
