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
    
    private struct OptionalText: Handler {
        let text: String?
        
        
        init(_ text: String?) {
            self.text = text
        }
        
        
        func handle() -> String? {
            text
        }
    }
    
    private struct ActionHandler: Handler {
        let action: Action<String>
        
        func handle() -> Action<String> {
            action
        }
    }
    
    private struct EmojiResponseTransformer: ResponseTransformer {
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
    
    private struct EmojiEncodableResponseTransformer: EncodableResponseTransformer {
        private let emojis: String


        init(emojis: String = "✅") {
            self.emojis = emojis
        }


        func transform(response: String) -> String {
            ResponseTransformerTests.emojiTransformerExpectation?.fulfill()
            return "\(emojis) \(response) \(emojis)"
        }
    }
    
    private struct OptionalEmojiResponseTransformer: ResponseTransformer {
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
    
    // swiftlint:disable:next type_name
    private struct OptionalEmojiEncodableResponseTransformer: EncodableResponseTransformer {
        private let emojis: String


        init(emojis: String = "✅") {
            self.emojis = emojis
        }


        func transform(response: String?) -> String {
            ResponseTransformerTests.emojiTransformerExpectation?.fulfill()
            return "\(emojis) \(response ?? "❓") \(emojis)"
        }
    }
    
    
    private func expect<T: Decodable & Comparable>(_ data: T, in response: XCTHTTPResponse) throws {
        XCTAssertEqual(response.status, .ok)
        let content = try response.content.decode(Content<T>.self)
        XCTAssert(content.data == data)
        waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testResponseMediator() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Text("Hello")
                    .response(EmojiEncodableResponseTransformer())
                Group("paul") {
                    Text("Hello Paul")
                        .operation(.update)
                        .response(EmojiEncodableResponseTransformer(emojis: "🚀"))
                }
                Group("bernd") {
                    Text("Hello Bernd")
                        .response(EmojiEncodableResponseTransformer())
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
    
    func testOptionalResponseTransformer() throws {
        struct TestWebService: WebService {
            var content: some Component {
                OptionalText(nil)
                    .response(OptionalEmojiResponseTransformer())
                Group("paul") {
                    OptionalText("Hello Paul")
                        .response(OptionalEmojiResponseTransformer(emojis: "🚀"))
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
        struct TestWebService: WebService {
            var content: some Component {
                OptionalText(nil)
                    .response(OptionalEmojiEncodableResponseTransformer())
                Group("paul") {
                    OptionalText("Hello Paul")
                        .response(OptionalEmojiEncodableResponseTransformer(emojis: "🚀"))
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
    
    func testEncodableResponseTransformer() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Group("nothing") {
                    ActionHandler(action: .end)
                        .response(EmojiEncodableResponseTransformer())
                }
                Group("send") {
                    ActionHandler(action: .send("Paul"))
                        .response(EmojiEncodableResponseTransformer())
                }
                Group("final") {
                    ActionHandler(action: .final("Paul"))
                        .response(EmojiEncodableResponseTransformer())
                }
                Group("automatic") {
                    ActionHandler(action: .automatic("Paul"))
                        .response(EmojiEncodableResponseTransformer())
                }
                Group("end") {
                    ActionHandler(action: .end)
                        .response(EmojiEncodableResponseTransformer())
                }
            }
        }
        
        TestWebService.main(app: app)
        
        try app.test(.GET, "/v1/nothing") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(response.body.readableBytes, 0)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.GET, "/v1/send") { res in
            try expect("✅ Paul ✅", in: res)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.GET, "/v1/final") { res in
            try expect("✅ Paul ✅", in: res)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is exectured")
        try app.test(.GET, "/v1/automatic") { res in
            try expect("✅ Paul ✅", in: res)
        }
        
        try app.test(.GET, "/v1/end") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(response.body.readableBytes, 0)
        }
    }
    
    func testFailingResponseTransformer() throws {
        let action: Action<Int> = .automatic(42)
        XCTAssertRuntimeFailure(
            EmojiEncodableResponseTransformer()
                .transform(response: action.typeErasured, on: self.app.eventLoopGroup.next())
        )
        
        XCTAssertRuntimeFailure(
            EmojiResponseTransformer()
                .transform(response: action.typeErasured, on: self.app.eventLoopGroup.next())
        )
        
        XCTAssertRuntimeFailure(
            OptionalEmojiEncodableResponseTransformer()
                .transform(response: action.typeErasured, on: self.app.eventLoopGroup.next())
        )
        
        XCTAssertRuntimeFailure(
            OptionalEmojiResponseTransformer()
                .transform(response: action.typeErasured, on: self.app.eventLoopGroup.next())
        )
    }
}
