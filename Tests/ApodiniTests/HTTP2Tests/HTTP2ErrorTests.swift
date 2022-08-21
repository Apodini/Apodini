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
    let host = "localhost"
    let port = 443
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
//        configuration.configure(app)
//
//        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
//        content.accept(visitor)
//        visitor.finishParsing()
//
//        try app.httpServer.start()
    }
    
    func testIncompleteRequest() throws {
//        let countExpectation = XCTestExpectation("Count the number of reponses")
//        countExpectation.assertForOverFulfill = true
//        countExpectation.expectedFulfillmentCount = 100
//        let errorExpectation = XCTestExpectation("An error occured!")
//        errorExpectation.isInverted = true
        
        let headerFields = BasicHTTPHeaderFields(.POST, "/http/add", "localhost")
        let delegate = IncompleteStreamingDelegate(headerFields)
        let client = try HTTP2StreamingClient(host, port)
        try client.startStreamingDelegate(delegate).flatMapAlways { result -> EventLoopFuture<Void> in
            switch result {
            case .failure(let failure):
                XCTAssertTrue(failure is NIOHTTP2Errors.StreamClosed)
            default:
                XCTFail("Did not catch error!")
            }
            return client.eventLoop.makeSucceededVoidFuture()
        }.wait()
    }
    
//    @ConfigurationBuilder
//    var configuration: Configuration {
//        HTTP()
//
//        HTTPConfiguration(
//            bindAddress: .interface("localhost", port: 4443),
//            tlsConfiguration: .init(
//                certificatePath: try! XCTUnwrap(Bundle.module.url(forResource: "apodini_https_cert_localhost.cer", withExtension: "pem")).path,
//                keyPath: try! XCTUnwrap(Bundle.module.url(forResource: "apodini_https_cert_localhost.key", withExtension: "pem")).path
//            )
//        )
//    }
//
//    @ComponentBuilder
//    var content: some Component {
//        AddHandler()
//    }

    final class IncompleteStreamingDelegate: StreamingDelegate {
        typealias SRequest = DATAFrameRequest<String>
        typealias SResponse = String
        var streamingHandler: HTTPClientStreamingHandler<IncompleteStreamingDelegate>?
        var headerFields: BasicHTTPHeaderFields
        
        func handleInbound(response: String, serverSideClosed: Bool) { }
        
        func handleInboundNotDecodable(buffer: ByteBuffer, serverSideClosed: Bool) {
            let str = buffer.getString(at: 0, length: buffer.readableBytes)
            XCTAssertEqual(str,
                "Bad Input: Didn't retrieve any parameters for a required parameter '@Parameter var sum: Int'. (keyNotFound(\"sum\", Swift.DecodingError.Context(codingPath: [\"query\"], debugDescription: \"No value associated with key sum (\\\"sum\\\").\", underlyingError: nil)))"
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
}
