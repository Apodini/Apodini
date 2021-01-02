//
//  VisitorTests.swift
//
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import XCTVapor
@testable import Apodini


final class EmojiResponseTransformerTests: ApodiniTests {
    private static var transformerExpectation: XCTestExpectation?
            
    struct EmojiMediator: ResponseTransformer {
        private let emojis: String
        
        
        init(emojis: String = "✅") {
            self.emojis = emojis
        }
        
        
        func transform(response: String) -> String {
            guard let transformerExpectation = EmojiResponseTransformerTests.transformerExpectation else {
                fatalError("The test expectation must be set before testing `EmojiMediator`")
            }
            transformerExpectation.fulfill()
            return "\(emojis) \(response) \(emojis)"
        }
    }
    
    struct TestWebService: WebService {
        var content: some Component {
            Text("Hello")
                .response(EmojiMediator())
            Group("paul") {
                Text("Hello Paul")
                    .operation(.update)
                    .response(EmojiMediator())
            }
            Group("bernd") {
                Text("Hello Bernd")
                    .response(EmojiMediator())
                    .operation(.create)
            }
        }
    }
    
    func testResponseMediator() throws {
        TestWebService.main(app: app)
        
        struct Content<T: Decodable>: Decodable {
            let data: T
        }
        
        func expect<T: Decodable & Comparable>(_ data: T, in response: XCTHTTPResponse) throws {
            XCTAssertEqual(response.status, .ok)
            let content = try response.content.decode(Content<T>.self)
            XCTAssert(content.data == data)
            waitForExpectations(timeout: 0, handler: nil)
        }
        
        EmojiResponseTransformerTests.transformerExpectation = self.expectation(description: "ResponseTransformer is exectured")
        try app.test(.GET, "/v1/") { res in
            try expect("✅ Hello ✅", in: res)
        }
        
        EmojiResponseTransformerTests.transformerExpectation = self.expectation(description: "ResponseTransformer is exectured")
        try app.test(.PUT, "/v1/paul/") { res in
            try expect("✅ Hello Paul ✅", in: res)
        }
        
        EmojiResponseTransformerTests.transformerExpectation = self.expectation(description: "ResponseTransformer is exectured")
        try app.test(.POST, "/v1/bernd/") { res in
            try expect("✅ Hello Bernd ✅", in: res)
        }
    }
}
