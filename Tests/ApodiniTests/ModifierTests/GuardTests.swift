//
//  GuardTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import XCTVapor
import protocol Fluent.Database
@testable import Apodini


final class GuardTests: ApodiniTests {
    private static var guardExpectation: XCTestExpectation?
    
    
    func testSyncGuard() throws {
        struct TestSyncGuard: SyncGuard {
            func check() {
                guard let guardExpectation = GuardTests.guardExpectation else {
                    fatalError("The test expectation must be set before testing `TestGuard`")
                }
                guardExpectation.fulfill()
            }
        }
        
        GuardTests.guardExpectation = self.expectation(description: "Guard is exectured")
        
        struct TestWebService: WebService {
            var version = Version(prefix: "v", major: 2, minor: 1, patch: 0)
            
            var content: some Component {
                Text("Hello")
                    .guard(TestSyncGuard())
            }
        }
        
        TestWebService.main(app: app)
        
        
        try app.test(.GET, "/v2/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == "Hello")
            waitForExpectations(timeout: 0, handler: nil)
        }
    }
    
    func testGuard() throws {
        struct TestGuard: Guard {
            @Apodini.Environment(\.database)
            var database: Database
            
            func check() -> EventLoopFuture<Void> {
                guard let guardExpectation = GuardTests.guardExpectation else {
                    fatalError("The test expectation must be set before testing `TestGuard`")
                }
                guardExpectation.fulfill()
                
                return database.eventLoop.makeSucceededFuture(Void())
            }
        }
        
        GuardTests.guardExpectation = self.expectation(description: "Guard is exectured")
        
        struct TestWebService: WebService {
            var version = Version(prefix: "v", major: 2, minor: 1, patch: 0)
            
            var content: some Component {
                Text("Hello")
                    .guard(TestGuard())
            }
        }
        
        TestWebService.main(app: app)
        
        
        try app.test(.GET, "/v2/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == "Hello")
            waitForExpectations(timeout: 0, handler: nil)
        }
    }
}
