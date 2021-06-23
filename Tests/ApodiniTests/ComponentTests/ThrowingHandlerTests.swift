//
//  ThrowingErrorTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/14/21.
//

@testable import Apodini
@testable import ApodiniREST
@testable import ApodiniVaporSupport
import XCTest
import Fluent
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
