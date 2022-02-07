//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
@testable import Apodini
@testable import ApodiniREST
import FluentKit
import XCTApodiniNetworking


class ThrowingErrorTests: ApodiniTests {
    struct MyError: Codable, Error {
        let reason: String
    }
    
    struct ThrowingHandler: Handler {
        func handle() throws -> String {
            throw MyError(reason: "The operation failed")
        }
    }
    
    struct ThrowingEventLoopFutureHandler: Handler {
        @Apodini.Environment(\.database)
        var database: Database
        
        func handle() throws -> EventLoopFuture<String> {
            database.eventLoop.makeFailedFuture(MyError(reason: "The operation failed"))
        }
    }
    
    struct ThrowingEventLoopFutureHandler2: Handler {
        @Apodini.Environment(\.eventLoopGroup)
        var eventLoopGroup: EventLoopGroup
        
        func handle() -> EventLoopFuture<String> {
            eventLoopGroup.next().makeFailedFuture(MyError(reason: "The operation failed"))
        }
    }
    
    
    func testThrowingHandlerUsingREST() throws {
        struct TestWebService: WebService {
            var content: some Component {
                ThrowingHandler()
            }
            var configuration: Configuration {
                REST()
            }
        }
        
        try TestWebService().start(app: app)
        
        try app.testable().test(.GET, "/") { res in
            XCTAssertEqual(res.status, .internalServerError)
            let responseText = try XCTUnwrap(res.bodyStorage.getFullBodyDataAsString())
            XCTAssertEqual(responseText, "MyError(reason: \"The operation failed\")")
        }
    }
    
    func testThrowingEventLoopFutureHandlerUsingREST() throws {
        struct TestWebService: WebService {
            var content: some Component {
                ThrowingEventLoopFutureHandler()
            }
            var configuration: Configuration {
                REST()
            }
        }
        
        try TestWebService().start(app: app)
        
        try app.testable().test(.GET, "/") { res in
            XCTAssertEqual(res.status, .internalServerError)
            let responseText = try XCTUnwrap(res.bodyStorage.getFullBodyDataAsString())
            XCTAssertEqual(responseText, "MyError(reason: \"The operation failed\")")
        }
    }
    
    
    func testThrowingEventLoopFutureHandler2() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                ThrowingEventLoopFutureHandler2()
            }
            var configuration: Configuration {
                REST()
            }
        }

        try WebService().start(app: app)
        
        try app.testable().test(.GET, "/") { response in
            XCTAssertEqual(response.status, .internalServerError)
            let responseText = try XCTUnwrap(response.bodyStorage.getFullBodyDataAsString())
            XCTAssertEqual(responseText, "MyError(reason: \"The operation failed\")")
        }
    }
}
