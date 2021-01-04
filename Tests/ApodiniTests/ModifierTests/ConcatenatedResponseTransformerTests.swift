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
    private static var thirdResponseMediatorExpectation: XCTestExpectation?
    
    
    struct FirstTestResponseMediator: EncodableResponseTransformer {
        func transform(response: String) -> Int {
            guard let number = Int(response) else {
                XCTFail("Could not convert \(response) to an `Int`")
                return 0
            }
            
            ConcatenatedResponseTransformerTests.firstResponseMediatorExpectation?.fulfill()
            
            return number
        }
    }
    
    struct SecondTestResponseMediator: ResponseTransformer {
        func transform(response: Action<Int>) -> Action<Double> {
            response.map { number -> Double in
                ConcatenatedResponseTransformerTests.secondResponseMediatorExpectation?.fulfill()
                return Double(number)
            }
        }
    }
    
    struct ThirdTestResponseMediator: EncodableResponseTransformer {
        func transform(response: Double) -> Bool {
            ConcatenatedResponseTransformerTests.thirdResponseMediatorExpectation?.fulfill()
            
            return response == 42.0
        }
    }
    
    
    func testResponseModifer() throws {
        ConcatenatedResponseTransformerTests.firstResponseMediatorExpectation = self.expectation(description: "First ResponseMediator is exectured")
        ConcatenatedResponseTransformerTests.secondResponseMediatorExpectation = self.expectation(description: "Second ResponseMediator is exectured")
        
        
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
    
    func testResponseModiferOrder() throws {
        ConcatenatedResponseTransformerTests.secondResponseMediatorExpectation = self.expectation(description: "Second ResponseMediator is exectured")
        ConcatenatedResponseTransformerTests.thirdResponseMediatorExpectation = self.expectation(description: "Third ResponseMediator is exectured")
        
        struct Number: Handler {
            let number: Int
            
            init(_ number: Int) {
                self.number = number
            }
            
            func handle() -> Int {
                number
            }
        }
        
        struct TestWebService: WebService {
            var content: some Component {
                Number(42)
                    .response(SecondTestResponseMediator())
                    .response(ThirdTestResponseMediator())
            }
        }
        
        TestWebService.main(app: app)
        
        try app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: Bool
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == true)
            waitForExpectations(timeout: 0, handler: nil)
        }
    }
    
    func testResponseModiferThree() throws {
        ConcatenatedResponseTransformerTests.firstResponseMediatorExpectation = self.expectation(description: "First ResponseMediator is exectured")
        ConcatenatedResponseTransformerTests.secondResponseMediatorExpectation = self.expectation(description: "Second ResponseMediator is exectured")
        ConcatenatedResponseTransformerTests.thirdResponseMediatorExpectation = self.expectation(description: "Third ResponseMediator is exectured")
        
        struct TestWebService: WebService {
            var content: some Component {
                Text("42")
                    .response(FirstTestResponseMediator())
                    .response(SecondTestResponseMediator())
                    .response(ThirdTestResponseMediator())
            }
        }
        
        TestWebService.main(app: app)
        
        try app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: Bool
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == true)
            waitForExpectations(timeout: 0, handler: nil)
        }
    }
}
