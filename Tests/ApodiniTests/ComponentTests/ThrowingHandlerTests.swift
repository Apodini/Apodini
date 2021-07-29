//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
@testable import ApodiniREST
@testable import ApodiniVaporSupport
import XCTest
import FluentKit
import Vapor

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
    
    
    func testThrowingHandlerUsingREST() throws {
        struct TestWebService: WebService {
            var content: some Component {
                ThrowingHandler()
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .internalServerError)
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
        
        TestWebService.start(app: app)
        
        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .internalServerError)
        }
    }
}
