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

class HTTP2ClientSideTests: XCTApodiniTest {
    override func setUpWithError() throws {
        try super.setUpWithError()

        httpsConfiguration.configure(app)

        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        http2Content.accept(visitor)
        visitor.finishParsing()

        try app.httpServer.start()
    }
    
    func testClientSideAdding() throws {
        // The client sends a bunch of numbers, which the server adds up
        
        let headerFields = BasicHTTPHeaderFields(.POST, "/cs", "localhost")
        let delegate = NumberSendingDelegate(headerFields)
        let client = try HTTP2StreamingClient("localhost", 4443)
        try client.startStreamingDelegate(delegate).wait()
    }

    final class NumberSendingDelegate: StreamingDelegate {
        typealias SRequest = DATAFrameRequest<NumberStruct>
        typealias SResponse = SumStruct
        var streamingHandler: HTTPClientStreamingHandler<NumberSendingDelegate>?
        var headerFields: BasicHTTPHeaderFields
        var hadResponse = false
        
        func handleInbound(response: SumStruct) {
            if hadResponse {
                XCTFail("Received more than one response!")
            }
            hadResponse = true
            // Verify response
            XCTAssertEqual(response.sum, 36)
        }
        
        func handleStreamStart() {
            let numStruct1 = NumberStruct(number: 1)
            let numStruct2 = NumberStruct(number: 2)
            let numStruct3 = NumberStruct(number: 3)
            let numStruct4 = NumberStruct(number: 4)
            let numStruct5 = NumberStruct(number: 5)
            let numStruct6 = NumberStruct(number: 6)
            let numStruct7 = NumberStruct(number: 7)
            let numStruct8 = NumberStruct(number: 8)
            
            sendOutbound(request: DATAFrameRequest(numStruct1))
            sendOutbound(request: DATAFrameRequest(numStruct2))
            sendOutbound(request: DATAFrameRequest(numStruct3))
            sendOutbound(request: DATAFrameRequest(numStruct4))
            sendOutbound(request: DATAFrameRequest(numStruct5))
            sendOutbound(request: DATAFrameRequest(numStruct6))
            sendOutbound(request: DATAFrameRequest(numStruct7))
            sendOutbound(request: DATAFrameRequest(numStruct8))
            close()
        }
        
        init(_ headerfields: BasicHTTPHeaderFields) {
            self.headerFields = headerfields
        }
    }
}
