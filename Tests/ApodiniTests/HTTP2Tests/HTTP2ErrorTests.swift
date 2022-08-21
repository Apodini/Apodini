//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//  

import Foundation
import XCTApodini
@testable import XCTApodiniNetworking
import ApodiniHTTP
@testable import Apodini

class HTTP2ErrorTests: XCTApodiniTest {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        AddStuff.configuration.configure(app)

        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        AddStuff.content.accept(visitor)
        visitor.finishParsing()

        try app.httpServer.start()
    }
    
    func testIncompleteRequest() throws {
        let headerFields = BasicHTTPHeaderFields(.POST, "/", "localhost")
        let delegate = IncompleteStreamingDelegate(headerFields)
        let client = try HTTP2StreamingClient("localhost", 4443)
        try client
            .startStreamingDelegate(delegate)
            .flatMapAlways { result -> EventLoopFuture<Void> in
                switch result {
                case .failure(let failure):
                    XCTAssertTrue(failure is NIOHTTP2Errors.StreamClosed)
                default:
                    XCTFail("Did not catch error!")
                }
                return client.eventLoop.makeSucceededVoidFuture()
            }
            .wait()
    }

    final class IncompleteStreamingDelegate: StreamingDelegate {
        typealias SRequest = DATAFrameRequest<String>
        typealias SResponse = String
        var streamingHandler: HTTPClientStreamingHandler<IncompleteStreamingDelegate>?
        var headerFields: BasicHTTPHeaderFields
        
        func handleInbound(response: String, serverSideClosed: Bool) { }
        
        func handleInboundNotDecodable(buffer: ByteBuffer, serverSideClosed: Bool) {
            let str = buffer.getString(at: 0, length: buffer.readableBytes)
            XCTAssertEqual(
                str,
                "Bad Input: Didn't retrieve any parameters for a required parameter '@Parameter var sum: Int'. (keyNotFound(\"sum\", Swift.DecodingError.Context(codingPath: [\"query\"], debugDescription: \"No value associated with key sum (\\\"sum\\\").\", underlyingError: nil)))" // swiftlint:disable:this line_length
            )
        }
        
        func handleStreamStart() {
            var msg = ByteBuffer(string: "{\"query\": {}}")
            
            streamingHandler?.sendLengthPrefixed(&msg)
        }
        
        init(_ headerfields: BasicHTTPHeaderFields) {
            self.headerFields = headerfields
        }
    }
    
    func testDoubleRequest() throws {
        let headerFields = BasicHTTPHeaderFields(.POST, "/ss", "localhost")
        let delegate = TwoRequestsStreamingDelegate(headerFields)
        let client = try HTTP2StreamingClient("localhost", 4443)
        try client
            .startStreamingDelegate(delegate)
            .flatMapAlways { result -> EventLoopFuture<Void> in
                switch result {
                case .failure(let failure):
                    XCTAssertTrue(failure is NIOHTTP2Errors.StreamClosed)
                default:
                    XCTFail("Did not catch error!")
                }
                return client.eventLoop.makeSucceededVoidFuture()
            }
            .wait()
    }
    
    final class TwoRequestsStreamingDelegate: StreamingDelegate {
        typealias SRequest = DATAFrameRequest<AddStruct>
        typealias SResponse = AddStruct
        var streamingHandler: HTTPClientStreamingHandler<TwoRequestsStreamingDelegate>?
        var headerFields: BasicHTTPHeaderFields
        
        func handleStreamStart() {
            let msg1 = AddStruct(sum: 0, number: 4)
            let msg2 = AddStruct(sum: 4, number: 5)
            
            streamingHandler?.sendOutbound(request: DATAFrameRequest(msg1))
            streamingHandler?.sendOutbound(request: DATAFrameRequest(msg2))
        }
        
        func handleInbound(response: AddStruct, serverSideClosed: Bool) { }
        
        init(_ headerfields: BasicHTTPHeaderFields) {
            self.headerFields = headerfields
        }
    }
}
