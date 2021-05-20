//
//  DelegationTests.swift
//  
//
//  Created by Max Obermeier on 17.05.21.
//

@testable import Apodini
import ApodiniREST
import XCTApodini
import XCTVapor
import XCTest


final class DelegationTests: ApodiniTests {
    struct TestDelegate {
        @Parameter var message: String
        @Apodini.Environment(\.connection) var connection
    }
    
    struct TestHandler: Handler {
        let testD = Delegate(TestDelegate())
        
        @Parameter var name: String
        
        @Throws(.forbidden) var badUserNameError: ApodiniError

        func handle() throws -> Apodini.Response<String> {
            guard name == "Max" else {
                return .final("Invalid Login")
            }
            
            let delegate = try testD()
            
            switch delegate.connection.state {
            case .open:
                return .send(delegate.message)
            case .end:
                return .final(delegate.message)
            }
        }
    }

    func testValidDelegateCall() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Max", "Hello, World!")
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: "Hello, World!",
            connectionEffect: .close
        )
    }
    
    func testMissingParameterDelegateCall() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Max")
        let context = endpoint.createConnectionContext(for: exporter)
        
        XCTAssertThrowsError(try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()).wait())
    }
    
    func testLazynessDelegateCall() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Not Max")
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: "Invalid Login",
            connectionEffect: .close
        )
    }
    
    func testConnectionAwareDelegate() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Max", "Hello, Paul!", "Max", "Hello, World!")
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next(), final: false),
            content: "Hello, Paul!",
            connectionEffect: .open
        )
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: "Hello, World!",
            connectionEffect: .close
        )
    }
}
