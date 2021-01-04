//
//  VisitorTests.swift
//
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import XCTVapor
@testable import Apodini


final class ResponseTransformerTests: ApodiniTests {
    private static var emojiTransformerExpectation: XCTestExpectation?
    private static var helloTransformerExpectation: XCTestExpectation?
    
    
    private struct Content<T: Decodable>: Decodable {
        let data: T
    }
    
    struct OptionalText: Handler {
        let text: String?
        
        
        init(_ text: String?) {
            self.text = text
        }
        
        
        func handle() -> String? {
            text
        }
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
            
            
            func transform(response: Action<String>) -> Action<String> {
                response.map { responseContent in
                    ResponseTransformerTests.emojiTransformerExpectation?.fulfill()
                    return "\(emojis) \(responseContent) \(emojis)"
                }
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
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.GET, "/v1/") { res in
            try expect("✅ Hello ✅", in: res)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.PUT, "/v1/paul/") { res in
            try expect("🚀 Hello Paul 🚀", in: res)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.POST, "/v1/bernd/") { res in
            try expect("✅ Hello Bernd ✅", in: res)
        }
    }
    
    func testActionShouldAllowResponseModifierOnWrappedType() throws {
        struct HelloResponseTransformer: EncodableResponseTransformer {
            func transform(response: String) -> String {
                ResponseTransformerTests.helloTransformerExpectation?.fulfill()
                
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
        
        ResponseTransformerTests.helloTransformerExpectation = self.expectation(description: "HelloResponseTransformer is exectured")
        try app.test(.GET, "/v1/") { res in
            try expect("Hello Paul", in: res)
        }
    }
    
    func testOptionalResponseMediator() throws {
        struct EmojiTransformer: ResponseTransformer {
            private let emojis: String


            init(emojis: String = "✅") {
                self.emojis = emojis
            }


            func transform(response: Action<String?>) -> Action<String> {
                response.map { responseContent in
                    ResponseTransformerTests.emojiTransformerExpectation?.fulfill()
                    return "\(emojis) \(responseContent ?? "❓") \(emojis)"
                }
            }
        }

        struct TestWebService: WebService {
            var content: some Component {
                OptionalText(nil)
                    .response(EmojiTransformer())
                Group("paul") {
                    OptionalText("Hello Paul")
                        .response(EmojiTransformer(emojis: "🚀"))
                }
            }
        }

        TestWebService.main(app: app)

        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.GET, "/v1/") { res in
            try expect("✅ ❓ ✅", in: res)
        }

        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.GET, "/v1/paul/") { res in
            try expect("🚀 Hello Paul 🚀", in: res)
        }
    }

    func testOptionalEncodableResponseMediator() throws {
        struct EmojiTransformer: EncodableResponseTransformer {
            private let emojis: String


            init(emojis: String = "✅") {
                self.emojis = emojis
            }


            func transform(response: String?) -> String {
                ResponseTransformerTests.emojiTransformerExpectation?.fulfill()
                return "\(emojis) \(response ?? "❓") \(emojis)"
            }
        }

        struct TestWebService: WebService {
            var content: some Component {
                OptionalText(nil)
                    .response(EmojiTransformer())
                Group("paul") {
                    OptionalText("Hello Paul")
                        .response(EmojiTransformer(emojis: "🚀"))
                }
            }
        }

        TestWebService.main(app: app)
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.GET, "/v1/") { res in
            try expect("✅ ❓ ✅", in: res)
        }

        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.GET, "/v1/paul/") { res in
            try expect("🚀 Hello Paul 🚀", in: res)
        }
    }
}
