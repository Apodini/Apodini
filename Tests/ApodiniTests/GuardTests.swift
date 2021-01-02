//
//  GuardTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import XCTVapor
@testable import Apodini


final class GuardTests: ApodiniTests {
    private static var guardExpectation: XCTestExpectation?
    
    
    private struct TestGuard: SyncGuard {
        func check() {
            guard let guardExpectation = GuardTests.guardExpectation else {
                fatalError("The test expectation must be set before testing `TestGuard`")
            }
            guardExpectation.fulfill()
        }
    }
    
    
    func testSyncGuard() throws {
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
            XCTAssertEqual(res.body.string, "\"Hello\"")
            waitForExpectations(timeout: 0, handler: nil)
        }
    }
}
