//
//  ConnectionTests.swift
//  
//
//  Created by Moritz Schüll on 21.12.20.
//

@testable import Apodini
import ApodiniREST
import XCTApodini
import XCTVapor
import XCTest


final class ConnectionTests: XCTApodiniDatabaseBirdTest {
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
        try XCTCheckHandler(TestHandler(endMessage: endMessage, openMessage: openMessage)) {
            MockRequest(expectation: endMessage)
        }
    }
    
    func testConnectionInjection() throws {
        try XCTCheckHandler(TestHandler(endMessage: endMessage, openMessage: openMessage)) {
            MockRequest(
                connectionState: .open,
                expectation: .response(connectionEffect: .open, openMessage)
            )
        }
        try XCTCheckHandler(TestHandler(endMessage: endMessage, openMessage: openMessage)) {
            MockRequest(
                connectionState: .end,
                expectation: .response(connectionEffect: .close, endMessage)
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
                ExporterConfiguration()
                    .exporter(RESTInterfaceExporter.self)
            }
        }

        TestWebService.main(app: app)

        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssert(res.body.string.contains("127.0.0.1:8080"))
        }
    }

    func testConnectionEventLoop() throws {
        struct TestHandler: Handler {
            @Apodini.Environment(\.connection)
            var connection: Connection

            func handle() -> String {
                connection.eventLoop.assertInEventLoop()
                return "success"
            }
        }
        
        struct TestWebService: WebService {
            var content: some Component {
                TestHandler()
            }

            var configuration: Configuration {
                ExporterConfiguration()
                    .exporter(RESTInterfaceExporter.self)
            }
        }

        TestWebService.main(app: app)

        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }
}
