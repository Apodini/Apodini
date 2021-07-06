//
//  ModifierTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTVapor
@testable import Apodini
@testable import ApodiniREST
@testable import ApodiniVaporSupport


final class ConcatenatedResponseTransformerTests: ApodiniTests {
    private static var firstResponseMediatorExpectation: XCTestExpectation?
    private static var secondResponseMediatorExpectation: XCTestExpectation?
    private static var thirdResponseMediatorExpectation: XCTestExpectation?
    
    
    struct FirstTestResponseMediator: ResponseTransformer {
        func transform(content string: String) -> Int {
            guard let number = Int(string) else {
                XCTFail("Could not convert \(string) to an `Int`")
                return 0
            }
            
            ConcatenatedResponseTransformerTests.firstResponseMediatorExpectation?.fulfill()
            return number
        }
    }
    
    struct SecondTestResponseMediator: ResponseTransformer {
        func transform(content number: Int) -> Double {
            ConcatenatedResponseTransformerTests.secondResponseMediatorExpectation?.fulfill()
            return Double(number)
        }
    }
    
    struct ThirdTestResponseMediator: ResponseTransformer {
        func transform(content number: Double) -> Bool {
            ConcatenatedResponseTransformerTests.thirdResponseMediatorExpectation?.fulfill()
            return number == 42.0
        }
    }
    
    
    func testResponseModifer() throws {
        ConcatenatedResponseTransformerTests.firstResponseMediatorExpectation = self.expectation(description: "First ResponseMediator is executed")
        ConcatenatedResponseTransformerTests.secondResponseMediatorExpectation = self.expectation(description: "Second ResponseMediator is executed")
        
        
        struct TestWebService: WebService {
            var content: some Component {
                Text("42")
                    .response(FirstTestResponseMediator())
                    .response(SecondTestResponseMediator())
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        try app.vapor.app.test(.GET, "/v1/") { res in
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
        ConcatenatedResponseTransformerTests.secondResponseMediatorExpectation = self.expectation(description: "Second ResponseMediator is executed")
        ConcatenatedResponseTransformerTests.thirdResponseMediatorExpectation = self.expectation(description: "Third ResponseMediator is executed")
        
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

            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        try app.vapor.app.test(.GET, "/v1/") { res in
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
        ConcatenatedResponseTransformerTests.firstResponseMediatorExpectation = self.expectation(description: "First ResponseMediator is executed")
        ConcatenatedResponseTransformerTests.secondResponseMediatorExpectation = self.expectation(description: "Second ResponseMediator is executed")
        ConcatenatedResponseTransformerTests.thirdResponseMediatorExpectation = self.expectation(description: "Third ResponseMediator is executed")
        
        struct TestWebService: WebService {
            var content: some Component {
                Text("42")
                    .response(FirstTestResponseMediator())
                    .response(SecondTestResponseMediator())
                    .response(ThirdTestResponseMediator())
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        try app.vapor.app.test(.GET, "/v1/") { res in
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
