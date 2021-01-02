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
    private static var emojiTransformerExpectation: XCTestExpectation?
    private static var helloTransformerExpectation: XCTestExpectation?
    
    private struct Content<T: Decodable>: Decodable {
        let data: T
    }
    
    private func expect<T: Decodable & Comparable>(_ data: T, in response: XCTHTTPResponse) throws {
        XCTAssertEqual(response.status, .ok)
        let content = try response.content.decode(Content<T>.self)
        XCTAssert(content.data == data)
        waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testResponseMediator() throws {
        struct EmojiTransformer: ResponseTransformer {
            private let emojis: String
            
            
            init(emojis: String = "✅") {
                self.emojis = emojis
            }
            
            
            func transform(response: String) -> String {
                guard let transformerExpectation = EmojiResponseTransformerTests.emojiTransformerExpectation else {
                    fatalError("The test expectation must be set before testing `EmojiTransformer`")
                }
                transformerExpectation.fulfill()
                return "\(emojis) \(response) \(emojis)"
            }
        }
        
        struct TestWebService: WebService {
            var content: some Component {
                Text("Hello")
                    .response(EmojiTransformer())
                Group("paul") {
                    Text("Hello Paul")
                        .operation(.update)
                        .response(EmojiTransformer(emojis: "🚀"))
                }
                Group("bernd") {
                    Text("Hello Bernd")
                        .response(EmojiTransformer())
                        .operation(.create)
                }
            }
        }
        
        TestWebService.main(app: app)
        
        EmojiResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.GET, "/v1/") { res in
            try expect("✅ Hello ✅", in: res)
        }
        
        EmojiResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.PUT, "/v1/paul/") { res in
            try expect("🚀 Hello Paul 🚀", in: res)
        }
        
        EmojiResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.POST, "/v1/bernd/") { res in
            try expect("✅ Hello Bernd ✅", in: res)
        }
    }
    
    func testActionShouldAllowResponseModifierOnWrappedType() throws {
        struct HelloResponseTransformer: ResponseTransformer {
            func transform(response: String) -> String {
                guard let transformerExpectation = EmojiResponseTransformerTests.helloTransformerExpectation else {
                    fatalError("The test expectation must be set before testing `EmojiTransformer`")
                }
                transformerExpectation.fulfill()
                
                return "Hello \(response)"
            }
        }

        struct TestHandler: Handler {
            func handle() -> Action<String> {
                .final("Paul")
            }
        }

        struct TestWebService: WebService {
            var content: some Component {
                TestHandler()
                    .response(HelloResponseTransformer())
            }
        }

        TestWebService.main(app: app)
        
        EmojiResponseTransformerTests.helloTransformerExpectation = self.expectation(description: "HelloResponseTransformer is exectured")
        try app.test(.GET, "/v1/") { res in
            try expect("Hello Paul", in: res)
        }
    }
}
