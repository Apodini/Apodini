//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

#if DEBUG || RELEASE_TESTING

import Apodini
@_exported import ApodiniNetworking
import XCTest
import AsyncHTTPClient


/// Testing request
public struct XCTHTTPRequest {
    /// HTTP version
    public let version: HTTPVersion
    /// HTTP method
    public let method: HTTPMethod
    /// URI
    public let url: URI
    /// headers
    public let headers: HTTPHeaders
    /// body
    public let body: ByteBuffer
    
    fileprivate let file: StaticString
    fileprivate let line: UInt
    
    /// Creates a testing request
    public init(
        version: HTTPVersion,
        method: HTTPMethod,
        url: URI,
        headers: HTTPHeaders = [:],
        body: ByteBuffer = .init(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.version = version
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.file = file
        self.line = line
    }
}


/// How a tester --- absent of any further information --- should treat the expected body of a response.
public enum XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType { // swiftlint:disable:this type_name
    /// buffer
    case buffer
    /// stream
    case stream
}


/// A proxy that can handle testing requests
public protocol XCTApodiniNetworkingRequestResponseTester {
    /// Perform a test
    /// - parameter request: The request to be tested
    /// - parameter expectedBodyType: Whether the response will be buffer- or stream-based
    /// - parameter responseStart: Block that will be invoked when the response starts (useful when dealing with stream-based responses). May be called on a different thread than this function's caller's
    /// - parameter responseEnd: Block that will be invoked when the response has ended. This is what should be used to perform tests etc against the response
    /// - Note: This function is synchronous, meaning that it will only return once the response has been fully received and the `responseEnd` block has returned
    func performTest(
        _ request: XCTHTTPRequest,
        expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType,
        responseStart: @escaping (HTTPResponse) throws -> Void,
        responseEnd: (HTTPResponse) throws -> Void
    ) throws
}


private func makeUrl(version: HTTPVersion, path: String) -> URI {
    URI(string: "\(version.major > 1 ? "https" : "http")://127.0.0.1:8000/\(path.hasPrefix("/") ? path.dropFirst() : path[...])")!
}

extension XCTApodiniNetworkingRequestResponseTester {
    /// Initiates a test request
    public func test(
        version: HTTPVersion = .http1_1,
        _ method: HTTPMethod,
        _ path: String,
        headers: HTTPHeaders = [:],
        body: ByteBuffer = .init(),
        expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType = .buffer,
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


extension Apodini.Application {
    public enum TestingMethod: Hashable {
        case inMemory
        case actualRequests(hostname: String?, port: Int?)
        
        public static var actualRequests: TestingMethod {
            .actualRequests(hostname: nil, port: nil)
        }
    }
    
    
    /// Creates a proxy application/request tester
    public func testable(_ methods: Set<TestingMethod> = [.inMemory]) -> XCTApodiniNetworkingRequestResponseTester {
        MultiplexingTester(testers: methods.map { method in
            switch method {
            case .inMemory:
                return InMemoryTester(app: self)
            case let .actualRequests(hostname, port):
                return ActualRequestsTester(app: self, hostname: hostname, port: port)
            }
        })
    }
    
    
    private struct MultiplexingTester: XCTApodiniNetworkingRequestResponseTester {
        let testers: [XCTApodiniNetworkingRequestResponseTester]
        
        func performTest(
            _ request: XCTHTTPRequest,
            expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType,
            responseStart: @escaping (HTTPResponse) throws -> Void,
            responseEnd: (HTTPResponse) throws -> Void
        ) throws {
            for tester in testers {
                try tester.performTest(request, expectedBodyType: expectedBodyType, responseStart: responseStart, responseEnd: responseEnd)
            }
        }
    }
    
    
    private struct InMemoryTester: XCTApodiniNetworkingRequestResponseTester {
        let app: Apodini.Application
        
        func performTest(
            _ request: XCTHTTPRequest,
            expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType,
            responseStart: @escaping (HTTPResponse) throws -> Void,
            responseEnd: (HTTPResponse) throws -> Void
        ) throws {
            let httpRequest = HTTPRequest(
                method: request.method,
                url: request.url,
                headers: request.headers,
                bodyStorage: .buffer(request.body),
                eventLoop: app.eventLoopGroup.next()
            )
            let response = try app.httpServer.respond(to: httpRequest).makeHTTPResponse(for: httpRequest).wait()
            try responseEnd(response)
        }
    }
    
    
    private struct ActualRequestsTester: XCTApodiniNetworkingRequestResponseTester {
        let app: Apodini.Application
        let hostname: String?
        let port: Int?
        
        init(app: Apodini.Application, hostname: String?, port: Int?) {
            self.app = app
            self.hostname = hostname
            self.port = port
        }
        
        func performTest(
            _ request: XCTHTTPRequest,
            expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType,
            responseStart: @escaping (HTTPResponse) throws -> Void,
            responseEnd: (HTTPResponse) throws -> Void
        ) throws {
            precondition(!app.httpServer.isRunning)
            let address: (hostname: String, port: Int)
            switch app.http.address {
            case let .hostname(currentAppHostname, port: currentAppPort):
                address = (hostname ?? currentAppHostname, port ?? currentAppPort)
                app.http.address = .hostname(address.hostname, port: address.port)
            case .unixDomainSocket:
                fatalError("Expected a hostname-based http config")
            }
            
            try app.httpServer.start()
            defer {
                try! app.httpServer.shutdown()
            }
            
            let httpClient = AsyncHTTPClient.HTTPClient(eventLoopGroupProvider: .shared(app.eventLoopGroup))
            defer {
                try! httpClient.syncShutdown()
            }
            
            let delegate = ActualRequestsTestHTTPClientResponseDelegate(
                expectedBodyType: expectedBodyType,
                responseStart: { response in
                    do {
                        try responseStart(response)
                    } catch {
                        XCTFail("\(error)", file: request.file, line: request.line)
                    }
                }
            )
            let responseTask = httpClient.execute(request: try AsyncHTTPClient.HTTPClient.Request(
                url: "\(request.url.scheme)://\(address.hostname):\(address.port)\(request.url.pathIncludingQueryAndFragment)",
                method: request.method,
                headers: request.headers,
                body: .byteBuffer(request.body),
                tlsConfiguration: .clientDefault
            ), delegate: delegate)
            
            let httpResponse = try responseTask.wait()
            try responseEnd(httpResponse)
        }
    }
}


private class ActualRequestsTestHTTPClientResponseDelegate: AsyncHTTPClient.HTTPClientResponseDelegate { // swiftlint:disable:this type_name
    typealias Response = HTTPResponse
    
    private let expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType
    private let response: HTTPResponse
    private let responseStart: (HTTPResponse) -> Void
    
    fileprivate init(
        expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType,
        responseStart: @escaping (HTTPResponse) -> Void
    ) {
        self.expectedBodyType = expectedBodyType
        self.responseStart = responseStart
        self.response = HTTPResponse(
            version: .http1_1,
            status: .imATeapot,
            headers: [:],
            bodyStorage: {
                switch expectedBodyType {
                case .buffer:
                    return .buffer()
                case .stream:
                    return .stream()
                }
            }()
        )
    }
    
    func didReceiveHead(task: HTTPClient.Task<Response>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        response.version = head.version
        response.status = head.status
        response.headers = head.headers
        responseStart(response)
        return task.eventLoop.makeSucceededVoidFuture()
    }
    
    
    func didReceiveBodyPart(task: HTTPClient.Task<Response>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
        response.bodyStorage.write(buffer)
        return task.eventLoop.makeSucceededVoidFuture()
    }
    
    func didFinishRequest(task: HTTPClient.Task<Response>) throws -> Response {
        response.bodyStorage.stream?.close()
        return response
    }
    
    func didReceiveError(task: HTTPClient.Task<Response>, _ error: Error) {
        print(#function, error)
        task.cancel()
    }
}

#endif // DEBUG || RELEASE_TESTING
