//
//  StateTests.swift
//  
//
//  Created by Max Obermeier on 14.01.21.
//

@testable import Apodini
import Vapor
import XCTApodini


class StateTests: ApodiniTests {
    struct TestHandler: Handler {
        @State var count: Int = 0
        
        
        func handle() -> Int {
            defer { count += 1 }
            return count
        }
    }
    
    struct CountGuard: SyncGuard {
        @State var count: Int = 0
        
        let callback: (Int) -> Void
        let expectation: XCTestExpectation
        
        
        func check() {
            callback(count)
            count += 1
            expectation.fulfill()
        }
    }
    
    struct AsyncCountGuard: Guard {
        @State var count: Int = 0

        let callback: (Int) -> Void
        let expectation: XCTestExpectation
        let eventLoop: EventLoop
        
        
        func check() -> EventLoopFuture<Void> {
            callback(count)
            count += 1
            expectation.fulfill()
            return eventLoop.makeSucceededFuture(())
        }
    }
    
    struct CountTransformer: ResponseTransformer {
        @State var count: Int = 0
        
        let expectation: XCTestExpectation
        
        
        func transform(content int: Int) -> String {
            defer {
                count += 1
                expectation.fulfill()
            }
            return String(repeating: "\(int)", count: count)
        }
    }
    
    class IntClass: Codable {
        var int: Int
        
        
        init(int: Int) {
            self.int = int
        }
    }
    
    struct TestHandlerUsingClassType: Handler {
        @State var count = IntClass(int: 0)
        
        
        func handle() -> Int {
            defer { count.int += 1 }
            return count.int
        }
    }
    
    struct CountGuardUsingClassType: SyncGuard {
        @State var count = IntClass(int: 0)
        
        let callback: (Int) -> Void
        let expectation: XCTestExpectation
        
        
        func check() {
            callback(count.int)
            count.int += 1
            expectation.fulfill()
        }
    }
    
    struct AsyncCountGuardUsingClassType: Guard {
        @State var count = IntClass(int: 0)

        let callback: (Int) -> Void
        let expectation: XCTestExpectation
        let eventLoop: EventLoop
        
        
        func check() -> EventLoopFuture<Void> {
            callback(count.int)
            count.int += 1
            expectation.fulfill()
            return eventLoop.makeSucceededFuture(())
        }
    }
    
    struct CountTransformerUsingClassType: ResponseTransformer {
        @State var count = IntClass(int: 0)
        
        let expectation: XCTestExpectation
        
        
        func transform(content int: Int) -> String {
            defer {
                count.int += 1
                expectation.fulfill()
            }
            return String(repeating: "\(int)", count: count.int)
        }
    }
    
    
    func testStateKeepsStateValueType() throws {
        var count: Int = 0
        let assertion = { number in
            XCTAssertEqual(number, count)
        }
        
        let guardExpectation = XCTestExpectation(expectedFulfillmentCount: 3)
        let asyncGuardExpectation = XCTestExpectation(expectedFulfillmentCount: 3)
        let transformerrExpectation = XCTestExpectation(expectedFulfillmentCount: 3)
        
        try newerXCTCheckHandler(
            TestHandler()
                .guard(CountGuard(callback: assertion, expectation: guardExpectation))
                .guard(AsyncCountGuard(callback: assertion, expectation: asyncGuardExpectation, eventLoop: self.app.eventLoopGroup.next()))
                .response(CountTransformer(expectation: transformerrExpectation))
        ) {
            MockRequest(expectation: "")
            ExecuteClosure<String> {
                count += 1
            }
            MockRequest(expectation: "1")
            ExecuteClosure<String> {
                count += 1
            }
            MockRequest(expectation: "22")
        }
        
        wait(for: [guardExpectation, asyncGuardExpectation, transformerrExpectation], timeout: 0)
    }
    
    func testStateIsNotSharedReferenceType() throws {
        let count: Int = 0
        let assertion = { number in
            XCTAssertEqual(number, count)
        }
        
        let guardExpectation = XCTestExpectation(expectedFulfillmentCount: 4)
        let asyncGuardExpectation = XCTestExpectation(expectedFulfillmentCount: 4)
        let transformerrExpectation = XCTestExpectation(expectedFulfillmentCount: 4)
        
        let handler = TestHandler()
            .guard(CountGuardUsingClassType(callback: assertion, expectation: guardExpectation))
            .guard(AsyncCountGuardUsingClassType(callback: assertion, expectation: asyncGuardExpectation, eventLoop: self.app.eventLoopGroup.next()))
            .response(CountTransformerUsingClassType(expectation: transformerrExpectation))
        
        
        // Not shared between in the same connection context
        try newerXCTCheckHandler(handler) {
            MockRequest(expectation: "")
            MockRequest(expectation: "", options: .doNotReuseConnection)
        }
        
        
        // Not shared across different instances of an exporter
        try newerXCTCheckHandler(handler) {
            MockRequest(expectation: "")
        }
        try newerXCTCheckHandler(handler) {
            MockRequest(expectation: "")
        }
        
        wait(for: [guardExpectation, asyncGuardExpectation, transformerrExpectation], timeout: 0)
    }

    func testStateIsNotSharedValueType() throws {
        let count: Int = 0
        let assertion = { number in
            XCTAssertEqual(number, count)
        }
        
        let guardExpectation = XCTestExpectation(expectedFulfillmentCount: 4)
        let asyncGuardExpectation = XCTestExpectation(expectedFulfillmentCount: 4)
        let transformerrExpectation = XCTestExpectation(expectedFulfillmentCount: 4)
        
        let handler = TestHandler()
            .guard(CountGuard(callback: assertion, expectation: guardExpectation))
            .guard(AsyncCountGuard(callback: assertion, expectation: asyncGuardExpectation, eventLoop: self.app.eventLoopGroup.next()))
            .response(CountTransformer(expectation: transformerrExpectation))
        
        
        // Not shared between in the same connection context
        try newerXCTCheckHandler(handler) {
            MockRequest(expectation: "")
            MockRequest(expectation: "", options: .doNotReuseConnection)
        }
        
        
        // Not shared across different instances of an exporter
        try newerXCTCheckHandler(handler) {
            MockRequest(expectation: "")
        }
        try newerXCTCheckHandler(handler) {
            MockRequest(expectation: "")
        }
        
        wait(for: [guardExpectation, asyncGuardExpectation, transformerrExpectation], timeout: 0)
    }
}
