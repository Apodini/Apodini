//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
import XCTApodini

class StateTests: ApodiniTests {
    struct CountGuard: Guard {
        @State var count: Int = 0
        let callback: (Int) -> Void
        
        func check() {
            callback(count)
            count += 1
        }
    }
    
    struct CountTransformer: ResponseTransformer {
        @State var count: Int = 0
        
        func transform(content int: Int) -> String {
            defer { count += 1 }
            return String(repeating: "\(int)", count: count)
        }
    }
    
    struct TestHandler: Handler {
        @State var count: Int = 0

        func handle() -> Int {
            defer { count += 1 }
            return count
        }
    }
    
    class IntClass: Codable {
        var int: Int
        
        init(int: Int) {
            self.int = int
        }
    }
    
    struct CountGuardUsingClassType: Guard {
        @State var count = IntClass(int: 0)
        
        let callback: (Int) -> Void
        
        func check() {
            callback(count.int)
            count.int += 1
        }
    }
    
    struct CountTransformerUsingClassType: ResponseTransformer {
        @State var count = IntClass(int: 0)
        
        func transform(content int: Int) -> String {
            defer { count.int += 1 }
            return String(repeating: "\(int)", count: count.int)
        }
    }
    
    struct TestHandlerUsingClassType: Handler {
        @State var count = IntClass(int: 0)

        func handle() -> Int {
            defer { count.int += 1 }
            return count.int
        }
    }
    
    func testStateKeepsStateValueType() throws {
        let eventLoop = app.eventLoopGroup.next()
        var count: Int = 0
        let assertion = { (number: Int) in  XCTAssertEqual(number, count) }
        let handler = TestHandler()
                        .transformed(CountTransformer())
                        .guarded(CountGuard(callback: assertion))
        
        let endpoint = handler.mockEndpoint()
        let exporter = MockExporter<String>()
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop),
            content: "",
            connectionEffect: .close
        )
        
        count += 1
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop),
            content: "1",
            connectionEffect: .close
        )
        
        count += 1
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop),
            content: "22",
            connectionEffect: .close
        )
    }
    
    func testStateIsNotSharedReferenceType() throws {
        let eventLoop = app.eventLoopGroup.next()
        let count: Int = 0
        let assertion = { (number: Int) in  XCTAssertEqual(number, count) }
        let handler = TestHandlerUsingClassType()
            .transformed(CountTransformerUsingClassType())
            .guarded(CountGuard(callback: assertion))
        
        let endpoint = handler.mockEndpoint()
        let exporter = MockExporter<String>()
        let context1 = endpoint.createConnectionContext(for: exporter)
        let context2 = endpoint.createConnectionContext(for: exporter)

        _ = try context1.handle(request: "Example Request", eventLoop: eventLoop).wait()

        // Call on this context should not be influenced by previous call. Thus do not increase `count`.
        try XCTCheckResponse(
            context2.handle(request: "Example Request", eventLoop: eventLoop),
            content: "",
            connectionEffect: .close
        )
    }
    
    func testStateIsNotSharedDifferentExportersReferenceType() throws {
        let eventLoop = app.eventLoopGroup.next()
        let count: Int = 0
        let assertion = { (number: Int) in  XCTAssertEqual(number, count) }
        let handler = TestHandlerUsingClassType()
            .transformed(CountTransformerUsingClassType())
            .guarded(CountGuard(callback: assertion))
        
        let endpoint = handler.mockEndpoint()
        let exporter1 = MockExporter<String>()
        let exporter2 = MockExporter<String>()
        let context1 = endpoint.createConnectionContext(for: exporter1)
        let context2 = endpoint.createConnectionContext(for: exporter2)

        _ = try context1.handle(request: "Example Request", eventLoop: eventLoop).wait()
        
        // Call on this context should not be influenced by previous call. Thus do not increase `count`.
        try XCTCheckResponse(
            context2.handle(request: "Example Request", eventLoop: eventLoop),
            content: "",
            connectionEffect: .close
        )
    }

    func testStateIsNotSharedValueType() throws {
        let eventLoop = app.eventLoopGroup.next()
        let count: Int = 0
        let assertion = { (number: Int) in  XCTAssertEqual(number, count) }
        let handler = TestHandler()
            .transformed(CountTransformer())
            .guarded(CountGuard(callback: assertion))
        
        let endpoint = handler.mockEndpoint()
        let exporter = MockExporter<String>()
        let context1 = endpoint.createConnectionContext(for: exporter)
        let context2 = endpoint.createConnectionContext(for: exporter)

        _ = try context1.handle(request: "Example Request", eventLoop: eventLoop).wait()

        // Call on this context should not be influenced by previous call. Thus do not increase `count`.
        try XCTCheckResponse(
            context2.handle(request: "Example Request", eventLoop: eventLoop),
            content: "",
            connectionEffect: .close
        )
    }
    
    func testStateIsNotSharedDifferentExportersValueType() throws {
        let eventLoop = app.eventLoopGroup.next()
        let count: Int = 0
        let assertion = { (number: Int) in  XCTAssertEqual(number, count) }
        let handler = TestHandler()
            .transformed(CountTransformer())
            .guarded(CountGuard(callback: assertion))
        
        let endpoint = handler.mockEndpoint()
        let exporter1 = MockExporter<String>()
        let exporter2 = MockExporter<String>()
        let context1 = endpoint.createConnectionContext(for: exporter1)
        let context2 = endpoint.createConnectionContext(for: exporter2)

        _ = try context1.handle(request: "Example Request", eventLoop: eventLoop).wait()

        // Call on this context should not be influenced by previous call. Thus do not increase `count`.
        try XCTCheckResponse(
            context2.handle(request: "Example Request", eventLoop: eventLoop),
            content: "",
            connectionEffect: .close
        )
    }
}
