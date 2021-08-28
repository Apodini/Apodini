//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

@testable import Apodini
@testable import ApodiniExtension
import XCTest
import ApodiniHTTPProtocol


final class CommunicationalPatternKnowledgeTests: ApodiniTests {
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

    
    func testAutomaticCommunicationalPattern() throws {
        let context = Context()
        
        let globalBlackboard = GlobalBlackboard<LazyHashmapBlackboard>(app)
        
        
        let basicRR = Greeter()
        let lbBasicRR = LocalBlackboard<
            LazyHashmapBlackboard,
            GlobalBlackboard<LazyHashmapBlackboard>
        >(globalBlackboard, using: basicRR, context)
        
        XCTAssertEqual(lbBasicRR[AutomaticCommunicationalPattern.self].value, .requestResponse)
        
        let blobRR = BlobGreeter()
        let lbBlobRR = LocalBlackboard<
            LazyHashmapBlackboard,
            GlobalBlackboard<LazyHashmapBlackboard>
        >(globalBlackboard, using: blobRR, context)
        
        XCTAssertEqual(lbBlobRR[AutomaticCommunicationalPattern.self].value, .requestResponse)
        
        let serviceSide = Rocket()
        let lbServiceSide = LocalBlackboard<
            LazyHashmapBlackboard,
            GlobalBlackboard<LazyHashmapBlackboard>
        >(globalBlackboard, using: serviceSide, context)
        
        XCTAssertEqual(lbServiceSide[AutomaticCommunicationalPattern.self].value, .serviceSideStream)
        
        let clientSide = ClientStreamingGreeter()
        let lbClientSide = LocalBlackboard<
            LazyHashmapBlackboard,
            GlobalBlackboard<LazyHashmapBlackboard>
        >(globalBlackboard, using: clientSide, context)
        
        XCTAssertEqual(lbClientSide[AutomaticCommunicationalPattern.self].value, .clientSideStream)
        
        let bidirectional = BidirectionalStreamingGreeter()
        let lbBidirectional = LocalBlackboard<
            LazyHashmapBlackboard,
            GlobalBlackboard<LazyHashmapBlackboard>
        >(globalBlackboard, using: bidirectional, context)
        
        XCTAssertEqual(lbBidirectional[AutomaticCommunicationalPattern.self].value, .bidirectionalStream)
    }
}
