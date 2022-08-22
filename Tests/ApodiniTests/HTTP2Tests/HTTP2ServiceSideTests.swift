//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//  

import Foundation
import XCTApodini
import XCTApodiniNetworking
import ApodiniHTTP
@testable import Apodini

class HTTP2ServiceSideTests: XCTApodiniTest {
    override func setUpWithError() throws {
        try super.setUpWithError()

        httpsConfiguration.configure(app)

        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        http2Content.accept(visitor)
        visitor.finishParsing()

        try app.httpServer.start()
    }
    
    func testServiceSideBlobStreaming() throws {
        let headerFields = BasicHTTPHeaderFields(.POST, "/ss2", "localhost")
        let delegate = BlobDelegate(headerFields)
        let client = try HTTP2StreamingClient("localhost", 4443)
        try client.startStreamingDelegate(delegate).wait()
    }

    final class BlobDelegate: StreamingDelegate {
        typealias SRequest = DATAFrameRequest<MaxStruct>
        typealias SResponse = AddStruct // Doesn't matter, we get data
        var streamingHandler: HTTPClientStreamingHandler<BlobDelegate>?
        var headerFields: BasicHTTPHeaderFields
        
        var nextExpectedLength = 1
        var max = 10
        
        func handleInbound(response: AddStruct, serverSideClosed: Bool) {
            XCTFail("Got decodable response??")
        }
        
        func handleInboundNotDecodable(buffer: ByteBuffer, serverSideClosed: Bool) {
            XCTAssertEqual(buffer.readableBytes, nextExpectedLength)
            XCTAssertTrue(nextExpectedLength <= max)
            nextExpectedLength += 1
        }
        
        func handleStreamStart() {
            let maxStruct = MaxStruct(max: max)
            
            sendOutbound(request: DATAFrameRequest(maxStruct))
            close()
        }
        
        init(_ headerfields: BasicHTTPHeaderFields) {
            self.headerFields = headerfields
        }
    }
}
