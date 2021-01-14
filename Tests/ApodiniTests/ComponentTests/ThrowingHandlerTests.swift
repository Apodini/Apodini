//
//  ThrowingErrorTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/14/21.
//

@testable import Apodini
import XCTest


class ThrowingErrorTests: ApodiniTests {
    struct MyError: Codable, Error {
        let reason: String
    }
    
    struct ThrowingHandler: Handler {
        func handle() throws -> String {
            throw MyError(reason: "The operation failed")
        }
    }
    
    struct TestWebService: WebService {
        var content: some Component {
            ThrowingHandler()
        }
    }
    
    
    func testThrowingHandlerUsingREST() throws {
        TestWebService.main(app: app)
        
        try app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .internalServerError)
        }
    }
    
    func testThrowingHandlerUsingGraphQL() throws {
        
    }
    
    func testThrowingHandlerUsingGRPC() throws {
        
    }
    
    func testThrowingHandlerUsingWebSockets() throws {
        
    }
}
