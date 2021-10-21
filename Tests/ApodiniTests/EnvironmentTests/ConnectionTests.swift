//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
import ApodiniREST
import XCTApodini
import XCTApodiniNetworking
import XCTest
import _NIOConcurrency


final class ConnectionTests: ApodiniTests {
    let endMessage = "End"
    let openMessage = "Open"
    
    struct TestHandler: Handler {
        @Apodini.Environment(\.connection)
        var connection: Connection
        
        var endMessage: String
        var openMessage: String
        
        func handle() -> Apodini.Response<String> {
            switch connection.state {
            case .open:
                return .send(openMessage)
            case .end:
                return .final(endMessage)
            }
        }
    }
    
    func testDefaultConnectionEnvironment() throws {
        var testHandler = TestHandler(endMessage: endMessage, openMessage: openMessage).inject(app: app)
        activate(&testHandler)
        
        let endpoint = testHandler.mockEndpoint(app: app)
        
        let exporter = MockExporter<String>()
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: endMessage,
            connectionEffect: .close
        )
    }
    
    func testConnectionInjection() throws {
        let mockRequest = MockRequest.createRequest(running: app.eventLoopGroup.next(), queuedParameters: .none)
        var testHandler = TestHandler(endMessage: endMessage, openMessage: openMessage).inject(app: app)
        activate(&testHandler)
        
        var connection = Connection(state: .open, request: mockRequest)
        _ = try connection.enterConnectionContext(with: testHandler) { handler in
            try XCTCheckResponse(
                handler.handle(),
                content: openMessage,
                connectionEffect: .open
            )
        }
        
        connection.state = .end
        _ = try connection.enterConnectionContext(with: testHandler) { handler in
            try XCTCheckResponse(
                handler.handle(),
                content: endMessage,
                connectionEffect: .close
            )
        }
    }

    func testConnectionRemoteAddress() throws {
        struct TestHandler: Handler {
            @Apodini.Environment(\.connection)
            var connection: Connection

            func handle() -> String {
                connection.remoteAddress?.description ?? "no remote"
            }
        }
        
        struct TestWebService: WebService {
            var content: some Component {
                TestHandler()
            }

            var configuration: Configuration {
                REST()
            }
        }

        TestWebService().start(app: app)

        //try app.vapor.app.test(.GET, "/v1/") { res in
        try app.testable().test(.GET, "/v1/") { res in
            // TODO this test probably was wrong before the Vapor rewrite.
            // It checks whether the body contains the specified address, but the thing is:
            // 1. there's two places where the body could contain the address (the data field, and the links field)
            // 2. the vapor-based version of the test used `app.vapor.app.test(.GET, ...)`. meaning that it'd use the .inMemory testing method, which doesnt actually send requests (and instead routes them directly internally), meaning that the remote address was already nil back when this was using vapor, and the reason why the test never failed before was that the response alwo contained the checked-for text in the links field
            // TODO is all of this correct?
            XCTAssertEqual(res.status, .ok)
            //print("AAAAAAAAA", String.init(data: res.bodyData, encoding: .utf8))
            //XCTAssert(res.body.string.contains("127.0.0.1:8080"))
            XCTAssert(try XCTUnwrap(res.bodyStorage.readNewDataAsString()).contains("0.0.0.0:8080"))
        }
    }
}
