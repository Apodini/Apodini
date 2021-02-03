//
//  ConnectionTests.swift
//  
//
//  Created by Moritz Schüll on 21.12.20.
//

@testable import Apodini
import XCTApodini
import XCTest


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
            expectedContent: endMessage,
            connectionEffect: .close
        )
    }
    
    func testConnectionInjection() throws {
        var testHandler = TestHandler(endMessage: endMessage, openMessage: openMessage).inject(app: app)
        activate(&testHandler)
        
        var connection = Connection(state: .open)
        _ = try connection.enterConnectionContext(with: testHandler) { handler in
            try XCTCheckResponse(
                handler.handle(),
                expectedContent: openMessage,
                connectionEffect: .open
            )
        }
        
        connection.state = .end
        _ = try connection.enterConnectionContext(with: testHandler) { handler in
            try XCTCheckResponse(
                handler.handle(),
                expectedContent: endMessage,
                connectionEffect: .close
            )
        }
    }
}
