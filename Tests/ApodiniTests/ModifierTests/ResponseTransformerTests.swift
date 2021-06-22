//
//  VisitorTests.swift
//
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import XCTVapor
import XCTApodini
@testable import Apodini
@testable import ApodiniREST
@testable import ApodiniVaporSupport


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
    
    
    private func expect<T: Decodable & Comparable>(_ data: T, in response: XCTHTTPResponse) throws {
        XCTAssertEqual(response.status, .ok)
        let content = try response.content.decode(Content<T>.self)
        XCTAssert(content.data == data)
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
        
        TestWebService.start(app: app)
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.vapor.app.test(.GET, "/v1/") { res in
            try expect("✅ Hello ✅", in: res)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.vapor.app.test(.PUT, "/v1/paul/") { res in
            try expect("🚀 Hello Paul 🚀", in: res)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.vapor.app.test(.POST, "/v1/bernd/") { res in
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

        TestWebService.start(app: app)

        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.vapor.app.test(.GET, "/v1/") { res in
            try expect("✅ ❓ ✅", in: res)
        }

        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.vapor.app.test(.GET, "/v1/paul/") { res in
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
                }
                Group("final") {
                    ResponseHandler(response: .final("Paul"))
                        .response(EmojiResponseTransformer())
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
        
        TestWebService.start(app: app)
        
        try app.vapor.app.test(.GET, "/v1/nothing") { response in
            XCTAssertEqual(response.status, .noContent)
            XCTAssertEqual(response.body.readableBytes, 0)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.vapor.app.test(.GET, "/v1/send") { res in
            try expect("✅ Paul ✅", in: res)
        }
        
        ResponseTransformerTests.emojiTransformerExpectation = self.expectation(description: "EmojiTransformer is executed")
        try app.vapor.app.test(.GET, "/v1/final") { res in
            try expect("✅ Paul ✅", in: res)
        }
        
        try app.vapor.app.test(.GET, "/v1/end") { response in
            XCTAssertEqual(response.status, .noContent)
            XCTAssertEqual(response.body.readableBytes, 0)
        }
    }
    
    func testFailingResponseTransformer() throws {
        let response: Apodini.Response<Int> = .final(42)
        XCTAssertRuntimeFailure(
            EmojiResponseTransformer()
                .transform(response: response.typeErasured, on: self.app.eventLoopGroup.next())
        )
        
        XCTAssertRuntimeFailure(
            EmojiResponseTransformer()
                .transform(response: response.typeErasured, on: self.app.eventLoopGroup.next())
        )
        
        XCTAssertRuntimeFailure(
            OptionalEmojiResponseTransformer()
                .transform(response: response.typeErasured, on: self.app.eventLoopGroup.next())
        )
        
        XCTAssertRuntimeFailure(
            OptionalEmojiResponseTransformer()
                .transform(response: response.typeErasured, on: self.app.eventLoopGroup.next())
        )
    }
}
