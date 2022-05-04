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
@testable @_exported import ApodiniNetworking
import AsyncHTTPClient


/// A HTTP request handling tester which dispatches all test requests by sending actual live requests to the HTTP responder.
struct ActualRequestsTester: XCTApodiniNetworkingHTTPRequestHandlingTester {
    let httpServer: HTTPServer
    let address: String?
    let port: Int?
    
    
    func performTest(
        _ request: XCTHTTPRequest,
        expectedBodyType: XCTApodiniNetworkingHTTPRequestHandlingTesterExpectedResponseBodyStorageType,
        responseStart: @escaping (HTTPResponse) throws -> Void,
        responseEnd: (HTTPResponse) throws -> Void
    ) throws {
        precondition(!httpServer.isRunning)
        httpServer.updateHTTPConfiguration(
            bindAddress: .init(address: self.address ?? httpServer.address.address, port: self.port ?? httpServer.address.port),
            hostname: nil,
            tlsConfiguration: nil
        )
        
        try httpServer.start()
        defer {
            try! httpServer.shutdown()
        }
        
        let httpClient = AsyncHTTPClient.HTTPClient(eventLoopGroupProvider: .shared(httpServer.eventLoopGroup))
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
            url: "\(request.url.scheme)://\(httpServer.addressString)\(request.url.pathIncludingQueryAndFragment)",
            method: request.method,
            headers: request.headers,
            body: .byteBuffer(request.body),
            tlsConfiguration: .clientDefault
        ), delegate: delegate)
        
        let httpResponse = try responseTask.wait()
        try responseEnd(httpResponse)
    }
}


private class ActualRequestsTestHTTPClientResponseDelegate: AsyncHTTPClient.HTTPClientResponseDelegate { // swiftlint:disable:this type_name
    typealias Response = HTTPResponse
    
    private let expectedBodyType: XCTApodiniNetworkingHTTPRequestHandlingTesterExpectedResponseBodyStorageType
    private let response: HTTPResponse
    private let responseStart: (HTTPResponse) -> Void
    
    fileprivate init(
        expectedBodyType: XCTApodiniNetworkingHTTPRequestHandlingTesterExpectedResponseBodyStorageType,
        responseStart: @escaping (HTTPResponse) -> Void
    ) {
        self.expectedBodyType = expectedBodyType
        self.responseStart = responseStart
        // Creating a placeholder response, the actual values are filled in once we receive the HEAD
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
