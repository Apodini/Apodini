//
//  EndToEndTests.swift
//  
//
//  Created by Max Obermeier on 01.07.21.
//

import XCTApodini
import ApodiniVaporSupport
import Vapor
import ApodiniHTTP
@testable import Apodini
import XCTVapor

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

        func handle() -> Blob {
            Blob("\(greeting ?? "Hello"), \(name)!".data(using: .utf8)!)
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
        
        func handle() -> Apodini.Response<String> {
            timer.secondPassed()
            counter += 1
            
            if counter == start {
                return .final("🚀🚀🚀 Launch !!! 🚀🚀🚀")
            } else {
                return .send("\(start - counter)...")
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
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/rr/Paul", body: nil) { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hello, Paul!")
        }
        
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/rr/Andi?greeting=Wuzzup", body: nil) { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Wuzzup, Andi!")
        }
    }
    
    func testServiceSideStreamingPattern() throws {
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/ss?start=10", body: nil) { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.content.decode([String].self, using: JSONDecoder()), [
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
        
        try app.vapor.app.testable(method: .inMemory)
            .test(.GET, "/cs", body: JSONEncoder().encodeAsByteBuffer(body, allocator: .init())) { response in
                XCTAssertEqual(response.status, .ok)
                XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hello, Germany, Taiwan and the World!")
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
        
        try app.vapor.app.testable(method: .inMemory)
            .test(.GET, "/bs", body: JSONEncoder().encodeAsByteBuffer(body, allocator: .init())) { response in
                XCTAssertEqual(response.status, .ok)
                XCTAssertEqual(try response.content.decode([String].self, using: JSONDecoder()), [
                    "Hello, Germany!",
                    "Hello, Taiwan!",
                    "Hello, World!"
                ])
            }
    }
    
    func testBlob() throws {
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/blob/Paul", body: nil) { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(response.body.string, "Hello, Paul!")
        }
        
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/blob/Andi?greeting=Wuzzup", body: nil) { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(response.body.string, "Wuzzup, Andi!")
        }
    }
}
