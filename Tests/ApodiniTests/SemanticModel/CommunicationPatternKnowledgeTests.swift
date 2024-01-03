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


final class CommunicationPatternKnowledgeTests: ApodiniTests {
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
        
        
        var metadata: any AnyHandlerMetadata {
            Pattern(.serviceSideStream)
        }
    }

    struct ClientStreamingGreeter: Handler {
        @Parameter(.http(.query)) var country: String?
        
        @Apodini.Environment(\.connection) var connection
        
        @State var list: [String] = []
        
        func handle() -> Apodini.Response<String> {
            switch connection.state {
            case .open:
                list.append(country ?? "the World")
                return .nothing
            case .end, .close:
                var response = "Hello, " + list[0..<list.count - 1].joined(separator: ", ")
                if let last = list.last {
                    response += " and " + last
                } else {
                    response += "everyone"
                }
                return .final(response + "!")
            }
        }
        
        var metadata: any AnyHandlerMetadata {
            Pattern(.clientSideStream)
        }
    }

    struct BidirectionalStreamingGreeter: Handler {
        @Parameter(.http(.query)) var country: String?
        
        @Apodini.Environment(\.connection) var connection
        
        func handle() -> Apodini.Response<String> {
            switch connection.state {
            case .open:
                return .send("Hello, \(country ?? "World")!")
            case .end, .close:
                return .end
            }
        }
        
        var metadata: any AnyHandlerMetadata {
            Pattern(.bidirectionalStream)
        }
    }

    
    func testAutomaticCommunicationPattern() throws {
        let context = Context()
        
        let globalSharedRepository = GlobalSharedRepository<LazyHashmapSharedRepository>(app)
        
        
        let basicRR = Greeter()
        let lbBasicRR = LocalSharedRepository<
            LazyHashmapSharedRepository,
            GlobalSharedRepository<LazyHashmapSharedRepository>
        >(globalSharedRepository, using: basicRR, context)
        
        XCTAssertEqual(lbBasicRR[AutomaticCommunicationPattern.self].value, .requestResponse)
        
        let blobRR = BlobGreeter()
        let lbBlobRR = LocalSharedRepository<
            LazyHashmapSharedRepository,
            GlobalSharedRepository<LazyHashmapSharedRepository>
        >(globalSharedRepository, using: blobRR, context)
        
        XCTAssertEqual(lbBlobRR[AutomaticCommunicationPattern.self].value, .requestResponse)
        
        let serviceSide = Rocket()
        let lbServiceSide = LocalSharedRepository<
            LazyHashmapSharedRepository,
            GlobalSharedRepository<LazyHashmapSharedRepository>
        >(globalSharedRepository, using: serviceSide, context)
        
        XCTAssertEqual(lbServiceSide[AutomaticCommunicationPattern.self].value, .serviceSideStream)
        
        let clientSide = ClientStreamingGreeter()
        let lbClientSide = LocalSharedRepository<
            LazyHashmapSharedRepository,
            GlobalSharedRepository<LazyHashmapSharedRepository>
        >(globalSharedRepository, using: clientSide, context)
        
        XCTAssertEqual(lbClientSide[AutomaticCommunicationPattern.self].value, .clientSideStream)
        
        let bidirectional = BidirectionalStreamingGreeter()
        let lbBidirectional = LocalSharedRepository<
            LazyHashmapSharedRepository,
            GlobalSharedRepository<LazyHashmapSharedRepository>
        >(globalSharedRepository, using: bidirectional, context)
        
        XCTAssertEqual(lbBidirectional[AutomaticCommunicationPattern.self].value, .bidirectionalStream)
    }
}
