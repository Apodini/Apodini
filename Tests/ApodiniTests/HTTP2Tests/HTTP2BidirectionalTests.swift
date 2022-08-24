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

class HTTP2BidirectionalTests: XCTApodiniTest {
    override func setUpWithError() throws {
        try super.setUpWithError()

        httpsConfiguration.configure(app)

        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        http2Content.accept(visitor)
        visitor.finishParsing()

        try app.httpServer.start()
    }
    
    func testBidirectionalAdding() throws {
        let countExpectation = XCTestExpectation("Count the number of reponses")
        countExpectation.assertForOverFulfill = true
        countExpectation.expectedFulfillmentCount = 100
        let errorExpectation = XCTestExpectation("An error occured!")
        errorExpectation.isInverted = true
        
        let headerFields = BasicHTTPHeaderFields(.POST, "/", "localhost")
        let delegate = AddStreamingDelegate(headerFields, errorExpectation, countExpectation)
        let client = try HTTP2StreamingClient("localhost", 4443)
        client.startStreamingDelegate(delegate)
        
        wait(for: [countExpectation, errorExpectation], timeout: 3.0)
    }

    final class AddStreamingDelegate: StreamingDelegate {
        typealias SRequest = DATAFrameRequest<AddStruct>
        typealias SResponse = AddStruct
        var streamingHandler: HTTPClientStreamingHandler<AddStreamingDelegate>?
        var headerFields: BasicHTTPHeaderFields
        
        var countExpectation: XCTestExpectation
        var errorExpectation: XCTestExpectation
        
        var responseCount = 0
        var nextExpectedSum = 0
        
        func handleInbound(response: AddStruct) {
            // Verify response
            if nextExpectedSum != response.sum {
                errorExpectation.fulfill()
            }
            
            countExpectation.fulfill()
            
            responseCount += 1
            if responseCount == 100 {
                close()
                return
            }
            
            let newNumber = Int.random(in: 0..<10)
            nextExpectedSum += response.number + newNumber
            let addStruct = AddStruct(sum: response.sum + response.number, number: newNumber)
            
            sendOutbound(request: DATAFrameRequest(addStruct))
        }
        
        func handleStreamStart() {
            nextExpectedSum = 4
            let addStruct = AddStruct(sum: 0, number: nextExpectedSum)
            
            sendOutbound(request: DATAFrameRequest(addStruct))
        }
        
        init(_ headerfields: BasicHTTPHeaderFields, _ errorExpectation: XCTestExpectation, _ countExpectation: XCTestExpectation) {
            self.headerFields = headerfields
            self.errorExpectation = errorExpectation
            self.countExpectation = countExpectation
        }
    }
}
