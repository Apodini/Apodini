//
//  ModifierTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
@testable import Apodini


final class ConcatenatedResponseTransformerTests: ApodiniTests {
    private static var firstResponseMediatorExpectation: XCTestExpectation?
    private static var secondResponseMediatorExpectation: XCTestExpectation?
    
    func testResponseModifer() throws {
        ConcatenatedResponseTransformerTests.firstResponseMediatorExpectation = self.expectation(description: "First ResponseMediator is exectured")
        ConcatenatedResponseTransformerTests.secondResponseMediatorExpectation = self.expectation(description: "Second ResponseMediator is exectured")
        
        struct FirstTestResponseMediator: ResponseTransformer {
            func transform(response: String) -> Int {
                guard let number = Int(response) else {
                    XCTFail("Could not convert \(response) to an `Int`")
                    return 0
                }
                
                guard let firstResponseMediatorExpectation = ConcatenatedResponseTransformerTests.firstResponseMediatorExpectation else {
                    fatalError("The test expectation must be set before testing `FirstTestResponseMediator`")
                }
                firstResponseMediatorExpectation.fulfill()
                
                return number
            }
        }
        
        struct SecondTestResponseMediator: ResponseTransformer {
            func transform(response: Int) -> Double {
                guard let secondResponseMediatorExpectation = ConcatenatedResponseTransformerTests.secondResponseMediatorExpectation else {
                    fatalError("The test expectation must be set before testing `SecondTestResponseMediator`")
                }
                secondResponseMediatorExpectation.fulfill()
                
                return Double(response)
            }
        }
        
        
        struct TestWebService: WebService {
            var content: some Component {
                Text("42")
                    .response(FirstTestResponseMediator())
                    .response(SecondTestResponseMediator())
            }
        }
        
        TestWebService.main(app: app)
        
        try app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: Double
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == 42.0)
            waitForExpectations(timeout: 0, handler: nil)
        }
    }
}
