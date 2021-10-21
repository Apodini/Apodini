//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTApodini
import ApodiniHTTP
@testable import Apodini
import XCTApodiniNetworking
import Foundation


class EndToEndTests: XCTApodiniTest {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        content.accept(visitor)
        visitor.finishParsing()
    }
    
    
    struct Greeter: Handler {
        @Parameter(.http(.path)) var name: String
        
        @Parameter(.http(.query)) var greeting: String?

        func handle() -> String {
            "\(greeting ?? "Hello"), \(name)!"
        }
    }
    
    struct BlobGreeter: Handler {
        @Parameter(.http(.path)) var name: String
        
        @Parameter(.http(.query)) var greeting: String?
        
        
        var metadata: Metadata {
            Pattern(.requestResponse)
        }
        
        func handle() -> Apodini.Response<Blob> {
            Response.send(
                Blob(Data("\(greeting ?? "Hello"), \(name)!".utf8), type: .text(.plain)),
                information: [AnyHTTPInformation(key: "Test", rawValue: "Test")]
            )
        }
    }

    class FakeTimer: Apodini.ObservableObject {
        @Apodini.Published private var _trigger = true
        
        init() {  }
        
        func secondPassed() {
            _trigger.toggle()
        }
    }


    struct Rocket: Handler {
        @Parameter(.http(.query), .mutability(.constant)) var start: Int = 10
        
        @State var counter = -1
        
        @ObservedObject var timer = FakeTimer()
        
        func handle() -> Apodini.Response<Blob> {
            timer.secondPassed()
            counter += 1
            
            if counter == start {
                return .final(Blob("🚀🚀🚀 Launch !!! 🚀🚀🚀\n".data(using: .utf8)!, type: .text(.plain)))
            } else {
                //return .send("\(start - counter)...")
                return .send(Blob("\(start - counter)...\n".data(using: .utf8)!, type: .text(.plain)))
            }
        }
        
        
        var metadata: AnyHandlerMetadata {
            Pattern(.serviceSideStream)
        }
    }

    struct ClientStreamingGreeter: Handler {
        @Parameter(.http(.query)) var country: String?
        
        @Apodini.Environment(\.connection) var connection
        
        @State var list: [String] = []
        
        func handle() -> Apodini.Response<String> {
            if connection.state == .end {
                var response = "Hello, " + list[0..<list.count - 1].joined(separator: ", ")
                if let last = list.last {
                    response += " and " + last
                } else {
                    response += "everyone"
                }
                
                return .final(response + "!")
            } else {
                list.append(country ?? "the World")
                return .nothing
            }
        }
        
        var metadata: AnyHandlerMetadata {
            Pattern(.clientSideStream)
        }
    }

    struct BidirectionalStreamingGreeter: Handler {
        @Parameter(.http(.query)) var country: String?
        
        @Apodini.Environment(\.connection) var connection
        
        func handle() -> Apodini.Response<String> {
            if connection.state == .end {
                return .end
            } else {
                return .send("Hello, \(country ?? "World")!")
            }
        }
        
        var metadata: AnyHandlerMetadata {
            Pattern(.bidirectionalStream)
        }
    }

    var configuration: Configuration {
        HTTP()
    }

    @ComponentBuilder
    var content: some Component {
        Group("rr") {
            Greeter()
        }
        Group("ss") {
            Rocket()
        }
        Group("cs") {
            ClientStreamingGreeter()
        }
        Group("bs") {
            BidirectionalStreamingGreeter()
        }
        Group("blob") {
            BlobGreeter()
        }
    }

    func testRequestResponsePattern() throws {
//        try app.vapor.app.testable(method: .inMemory).test(.GET, "/rr/Paul", body: nil) { response in
//            XCTAssertEqual(response.status, .ok)
//            XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hello, Paul!")
//        }
        try app.testable().test(.GET, "/rr/Paul") { response in
            XCTAssertEqual(response.status, .ok)
            //XCTAssertEqual(try response.decodeBody(as: String.self, using: JSONDecoder()), "Hello, Paul!")
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Hello, Paul!")
        }
        
//        try app.vapor.app.testable(method: .inMemory).test(.GET, "/rr/Andi?greeting=Wuzzup", body: nil) { response in
//            XCTAssertEqual(response.status, .ok)
//            XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Wuzzup, Andi!")
//        }
        try app.testable().test(.GET, "/rr/Andi?greeting=Wuzzup") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Wuzzup, Andi!")
        }
    }
    
    func testServiceSideStreamingPattern() throws {
//        try app.vapor.app.testable(method: .inMemory).test(.GET, "/ss?start=10", body: nil) { response in
//            XCTAssertEqual(response.status, .ok)
//            XCTAssertEqual(try response.content.decode([String].self, using: JSONDecoder()), [
//                "10...",
//                "9...",
//                "8...",
//                "7...",
//                "6...",
//                "5...",
//                "4...",
//                "3...",
//                "2...",
//                "1...",
//                "🚀🚀🚀 Launch !!! 🚀🚀🚀"
//            ])
//        }
        
//        let fullBodyReceivedExpectation = XCTestExpectation(description: "Full service-side stream body received")
        
//        HTTP2Configuration(
//            cert: "/Users/lukas/Documents/apodini certs/localhost.cer.pem",
//            keyPath: "/Users/lukas/Documents/apodini certs/localhost.key.pem"
//        ).configure(app)
        
        try app.testable([.actualRequests]).test(
            version: .http1_1,
            .GET,
            "/ss?start=10",
            expectedBodyType: .stream,
            responseStart: { response in
                response.bodyStorage.stream?.setObserver { stream, event in
                    print("STREAM EVENT", event)
                }
            },
            responseEnd: { response in
                XCTAssertEqual(response.status, .ok)
                let responseStream = try XCTUnwrap(response.bodyStorage.stream)
                XCTAssert(responseStream.isClosed)
                let responseText = try XCTUnwrap(response.bodyStorage.readNewDataAsString()).trimmingLeadingAndTrailingWhitespace() // We want to get rid of leading and trailing newlines since that would mess up the line splitting
                XCTAssertEqual(responseText.split(separator: "\n"), [
                    "10...",
                    "9...",
                    "8...",
                    "7...",
                    "6...",
                    "5...",
                    "4...",
                    "3...",
                    "2...",
                    "1...",
                    "🚀🚀🚀 Launch !!! 🚀🚀🚀"
                ])
            }
        )
    }
    
    func testClientSideStreamingPattern() throws {
        let body = [
            [
                "query": [
                    "country": "Germany"
                ]
            ],
            [
                "query": [
                    "country": "Taiwan"
                ]
            ],
            [String: [String: String]]()
        ]
        
//        try app.vapor.app.testable(method: .inMemory)
//            .test(.GET, "/cs", body: JSONEncoder().encodeAsByteBuffer(body, allocator: .init())) { response in
//                XCTAssertEqual(response.status, .ok)
//                XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hello, Germany, Taiwan and the World!")
//            }
        //try app.testable().test(.GET, "/cs", body: JSONEncoder().encodeAsByteBuffer(body, allocator: .init())) { response in
        try app.testable().test(.GET, "/cs", body: .init(data: JSONEncoder().encode(body))) { response in
            XCTAssertEqual(response.status, .ok)
            //print("LABEL", response.body.readString(length: response.body.readableBytes))
            XCTAssertEqual(try! response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Hello, Germany, Taiwan and the World!")
        }
    }
    
    func testBidirectionalStreamingPattern() throws {
        let body = [
            [
                "query": [
                    "country": "Germany"
                ]
            ],
            [
                "query": [
                    "country": "Taiwan"
                ]
            ],
            [String: [String: String]]()
        ]
        
//        try app.vapor.app.testable(method: .inMemory)
//            .test(.GET, "/bs", body: JSONEncoder().encodeAsByteBuffer(body, allocator: .init())) { response in
//                XCTAssertEqual(response.status, .ok)
//                XCTAssertEqual(try response.content.decode([String].self, using: JSONDecoder()), [
//                    "Hello, Germany!",
//                    "Hello, Taiwan!",
//                    "Hello, World!"
//                ])
//            }
        try app.testable().test(.GET, "/bs", body: JSONEncoder().encodeAsByteBuffer(body, allocator: .init())) { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: [String].self, using: JSONDecoder()), [
                "Hello, Germany!",
                "Hello, Taiwan!",
                "Hello, World!"
            ])
        }
    }
    
    func testBlob() throws {
//        try app.vapor.app.testable(method: .inMemory).test(.GET, "/blob/Paul", body: nil) { response in
//            XCTAssertEqual(response.status, .ok)
//            XCTAssertEqual(response.body.string, "Hello, Paul!")
//            XCTAssertEqual(response.headers["Content-Type"].first, "text/plain")
//            XCTAssertEqual(response.headers["Test"].first, "Test")
//        }
        try app.testable().test(.GET, "/blob/Paul") { response in
            XCTAssertEqual(response.status, .ok)
            //XCTAssertEqual(response.body.string, "Hello, Paul!")
            //XCTAssertEqual(response.body.readString(length: response.body.readableBytes), "Hello, Paul!")
            XCTAssertEqual(response.bodyStorage.readNewDataAsString(), "Hello, Paul!")
            XCTAssertEqual(response.headers["Content-Type"].first, "text/plain")
            XCTAssertEqual(response.headers["Test"].first, "Test")
        }
        
//        try app.vapor.app.testable(method: .inMemory).test(.GET, "/blob/Andi?greeting=Wuzzup", body: nil) { response in
//            XCTAssertEqual(response.status, .ok)
//            XCTAssertEqual(response.body.string, "Wuzzup, Andi!")
//            XCTAssertEqual(response.headers["Content-Type"].first, "text/plain")
//            XCTAssertEqual(response.headers["Test"].first, "Test")
//        }
        try app.testable().test(.GET, "/blob/Andi?greeting=Wuzzup") { response in
            XCTAssertEqual(response.status, .ok)
            //XCTAssertEqual(response.body.string, "Wuzzup, Andi!")
            XCTAssertEqual(response.bodyStorage.readNewDataAsString(), "Wuzzup, Andi!")
            XCTAssertEqual(response.headers["Content-Type"].first, "text/plain")
            XCTAssertEqual(response.headers["Test"].first, "Test")
        }
    }
}
