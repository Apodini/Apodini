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
        
        configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        content.accept(visitor)
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
        try HTTP2StreamingClient.client.startStreamingDelegate(delegate)
        
        wait(for: [countExpectation, errorExpectation], timeout: 1.0)
    }
    
    @ConfigurationBuilder
    var configuration: Configuration {
        HTTP()
        
        HTTPConfiguration(
            bindAddress: .interface("localhost", port: 4443),
            tlsConfiguration: .init(
                certificatePath: try! XCTUnwrap(Bundle.module.url(forResource: "apodini_https_cert_localhost.cer", withExtension: "pem")).path,
                keyPath: try! XCTUnwrap(Bundle.module.url(forResource: "apodini_https_cert_localhost.key", withExtension: "pem")).path
            )
        )
    }

    @ComponentBuilder
    var content: some Component {
        AddHandler()
    }
    
    struct AddStruct: Codable {
        let sum: Int
        let number: Int
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
        
        func handleInbound(response: AddStruct, serverSideClosed: Bool) {
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
            nextExpectedSum = response.sum + response.number + newNumber
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

    struct AddHandler: Handler {
        @Parameter(.http(.query)) var sum: Int
        @Parameter(.http(.query)) var number: Int
        @Environment(\.connection) var connection: Connection
        @State var nextExpectedSum = 0
        
        func handle() -> Response<AddStruct> {
            switch connection.state {
            case .close:
                return .final()
            default:
                break
            }
            
            // Verify that the request is correct given the last response we sent
            if sum != nextExpectedSum {
                let failAddStruct = AddStruct(sum: -1, number: -1)
                return .final(failAddStruct)
            }
            
            let newNumber = Int.random(in: 0..<10)
            let confirmedSum = self.sum + self.number
            self.nextExpectedSum = confirmedSum + newNumber
            let responseAddStruct = AddStruct(sum: confirmedSum, number: newNumber)
            
            
            switch connection.state {
            case .open:
                return .send(responseAddStruct)
            case .end:
                return .final(responseAddStruct)
            default:
                return .final()
            }
        }
        
        var metadata: AnyHandlerMetadata {
            Pattern(.bidirectionalStream)
            Operation(.create)
        }
    }
}
