//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import XCTApodini
@testable import Apodini
@testable import ApodiniREST
import XCTApodiniNetworking


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
    
    private struct ResponseHandler: Handler {
        let response: Apodini.Response<String>
        
        func handle() -> Apodini.Response<String> {
            response
        }
    }
    
    private struct EmojiResponseTransformer: ResponseTransformer {
        private let emojis: String


        init(emojis: String = "✅") {
            self.emojis = emojis
        }


        func transform(content string: String) -> String {
            ResponseTransformerTests.emojiTransformerExpectation?.fulfill()
            return "\(emojis) \(string) \(emojis)"
        }
    }
    
    private struct OptionalEmojiResponseTransformer: ResponseTransformer {
        private let emojis: String


        init(emojis: String = "✅") {
            self.emojis = emojis
        }


        func transform(content string: String?) -> String {
            ResponseTransformerTests.emojiTransformerExpectation?.fulfill()
            return "\(emojis) \(string ?? "❓") \(emojis)"
        }
    }
    
    
    private func expect<T: Decodable & Comparable>(_ data: T, in response: HTTPResponse) throws {
        XCTAssertEqual(response.status, .ok)
        let content = try response.bodyStorage.getFullBodyData(decodedAs: Content<T>.self)
        XCTAssert(content.data == data, "Expected \(data) but got \(content.data)")
        waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testSimpleResponseTransformer() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Text("Hello")
                    .response(EmojiResponseTransformer())
                Group("paul") {
                    Text("Hello Paul")
                        .operation(.update)
                        .response(EmojiResponseTransformer(emojis: "🚀"))
                }
                Group("bernd") {
                    Text("Hello Bernd")
                        .response(EmojiResponseTransformer())
                        .operation(.create)
                }
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        try TestWebService().start(app: app)
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.testable().test(.GET, "/") { res in
            try expect("✅ Hello ✅", in: res)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.testable().test(.PUT, "/paul/") { res in
            try expect("🚀 Hello Paul 🚀", in: res)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.testable().test(.POST, "/bernd/") { res in
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

            var configuration: Configuration {
                REST()
            }
        }

        try TestWebService().start(app: app)

        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.testable().test(.GET, "/") { res in
            try expect("✅ ❓ ✅", in: res)
        }

        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.testable().test(.GET, "/paul/") { res in
            try expect("🚀 Hello Paul 🚀", in: res)
        }
    }
    
    func testResponseTransformer() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Group("nothing") {
                    ResponseHandler(response: .nothing)
                        .response(EmojiResponseTransformer())
                }
                Group("send") {
                    ResponseHandler(response: .send("Paul"))
                        .response(EmojiResponseTransformer())
                        .response(EmojiResponseTransformer(emojis: "🚀"))
                }
                Group("final") {
                    ResponseHandler(response: .final("Paul"))
                        .response(EmojiResponseTransformer())
                        .response(EmojiResponseTransformer(emojis: "🚀"))
                        .response(EmojiResponseTransformer(emojis: "🎸"))
                }
                Group("end") {
                    ResponseHandler(response: .end)
                        .response(EmojiResponseTransformer())
                }
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        try TestWebService().start(app: app)
        
        try app.testable().test(.GET, "/nothing") { response in
            XCTAssertEqual(response.status, .noContent)
            XCTAssertEqual(response.bodyStorage.readableBytes, 0)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        ResponseTransformerTests.emojiTransformerExpectation?.expectedFulfillmentCount = 2
        try app.testable().test(.GET, "/send") { res in
            try expect("🚀 ✅ Paul ✅ 🚀", in: res)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        ResponseTransformerTests.emojiTransformerExpectation?.expectedFulfillmentCount = 3
        try app.testable().test(.GET, "/final") { res in
            try expect("🎸 🚀 ✅ Paul ✅ 🚀 🎸", in: res)
        }
        
        try app.testable().test(.GET, "/end") { response in
            XCTAssertEqual(response.status, .noContent)
            XCTAssertEqual(response.bodyStorage.readableBytes, 0)
        }
    }
    
    func testFailingResponseTransformer() throws {
        let response: Apodini.Response<Int> = .final(42)
        XCTAssertRuntimeFailure(
            EmojiResponseTransformer()
                .transform(response: response.typeErased, on: self.app.eventLoopGroup.next())
        )
        
        XCTAssertRuntimeFailure(
            EmojiResponseTransformer()
                .transform(response: response.typeErased, on: self.app.eventLoopGroup.next())
        )
        
        XCTAssertRuntimeFailure(
            OptionalEmojiResponseTransformer()
                .transform(response: response.typeErased, on: self.app.eventLoopGroup.next())
        )
        
        XCTAssertRuntimeFailure(
            OptionalEmojiResponseTransformer()
                .transform(response: response.typeErased, on: self.app.eventLoopGroup.next())
        )
    }
}
