//
//  StateTests.swift
//  
//
//  Created by Max Obermeier on 14.01.21.
//

import XCTest
@testable import Apodini
import Vapor

class StateTests: ApodiniTests {
    struct CountGuard: SyncGuard {
        @State var count: Int = 0
        
        let callback: (Int) -> Void
        
        func check() {
            callback(count)
            count += 1
        }
    }
    
    struct AsyncCountGuard: Guard {
        @State var count: Int = 0

        let callback: (Int) -> Void
        
        let eventLoop: EventLoop
        
        func check() -> EventLoopFuture<Void> {
            callback(count)
            count += 1
            return eventLoop.makeSucceededFuture(())
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
    
    struct CountGuardUsingClassType: SyncGuard {
        @State var count = IntClass(int: 0)
        
        let callback: (Int) -> Void
        
        func check() {
            callback(count.int)
            count.int += 1
        }
    }
    
    struct AsyncCountGuardUsingClassType: Guard {
        @State var count = IntClass(int: 0)

        let callback: (Int) -> Void
        
        let eventLoop: EventLoop
        
        func check() -> EventLoopFuture<Void> {
            callback(count.int)
            count.int += 1
            return eventLoop.makeSucceededFuture(())
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
        
        let syncGuard = { AnyGuard(CountGuard(callback: assertion)) }
        let asyncGuard = { AnyGuard(AsyncCountGuard(callback: assertion, eventLoop: eventLoop)) }
        
        let endpoint = handler.mockEndpoint(
            guards: [syncGuard, asyncGuard],
            responseTransformers: [ { CountTransformer() } ])

        let exporter = MockExporter<String>()

        let context = endpoint.createConnectionContext(for: exporter)
        
        var response = try context.handle(request: "Example Request", eventLoop: eventLoop)
                .wait()
        
        switch response.typed(String.self) {
        case .some(.final("")):
            break
        default:
            XCTFail("""
                Return value did not match expected value.
                This is most likely caused by the default value of 'Parameter' being shared across 'Handler's.
            """)
        }
        count += 1
        response = try context.handle(request: "Example Request", eventLoop: eventLoop)
                .wait()
        
        switch response.typed(String.self) {
        case .some(.final("1")):
            break
        default:
            XCTFail("""
                Return value did not match expected value.
                This is most likely caused by the default value of 'Parameter' being shared across 'Handler's.
            """)
        }
        count += 1
        response = try context.handle(request: "Example Request", eventLoop: eventLoop)
                .wait()
        
        switch response.typed(String.self) {
        case .some(.final("22")):
            break
        default:
            XCTFail("""
                Return value did not match expected value.
                This is most likely caused by the default value of 'Parameter' being shared across 'Handler's.
            """)
        }
    }
    
    func testStateIsNotSharedReferenceType() throws {
        let eventLoop = app.eventLoopGroup.next()

        let count: Int = 0

        let assertion = { (number: Int) in  XCTAssertEqual(number, count) }

        let handler = TestHandlerUsingClassType()

        let syncGuard = { AnyGuard(CountGuardUsingClassType(callback: assertion)) }
        let asyncGuard = { AnyGuard(AsyncCountGuardUsingClassType(callback: assertion, eventLoop: eventLoop)) }
        
        let endpoint = handler.mockEndpoint(
            guards: [syncGuard, asyncGuard],
            responseTransformers: [ { CountTransformerUsingClassType() } ])

        let exporter = MockExporter<String>()

        let context1 = endpoint.createConnectionContext(for: exporter)
        let context2 = endpoint.createConnectionContext(for: exporter)

        _ = try context1.handle(request: "Example Request", eventLoop: eventLoop)
                .wait()

        // Call on this context should not be influenced by previous call. Thus do not increase `count`.
        let response = try context2.handle(request: "Example Request", eventLoop: eventLoop)
                .wait()

        switch response.typed(String.self) {
        case .some(.final("")):
            break
        default:
            XCTFail("""
                Return value did not match expected value.
                This is most likely caused by the default value of 'Parameter' being shared across 'Handler's.
            """)
        }
    }
    
    func testStateIsNotSharedDifferentExportersReferenceType() throws {
        let eventLoop = app.eventLoopGroup.next()

        let count: Int = 0

        let assertion = { (number: Int) in  XCTAssertEqual(number, count) }

        let handler = TestHandlerUsingClassType()

        let syncGuard = { AnyGuard(CountGuardUsingClassType(callback: assertion)) }
        let asyncGuard = { AnyGuard(AsyncCountGuardUsingClassType(callback: assertion, eventLoop: eventLoop)) }
        
        let endpoint = handler.mockEndpoint(
            guards: [syncGuard, asyncGuard],
            responseTransformers: [ { CountTransformerUsingClassType() } ])

        let exporter1 = MockExporter<String>()
        let exporter2 = MockExporter<String>()

        let context1 = endpoint.createConnectionContext(for: exporter1)
        let context2 = endpoint.createConnectionContext(for: exporter2)

        _ = try context1.handle(request: "Example Request", eventLoop: eventLoop)
                .wait()

        // Call on this context should not be influenced by previous call. Thus do not increase `count`.
        let response = try context2.handle(request: "Example Request", eventLoop: eventLoop)
                .wait()

        switch response.typed(String.self) {
        case .some(.final("")):
            break
        default:
            XCTFail("""
                Return value did not match expected value.
                This is most likely caused by the default value of 'Parameter' being shared across 'Handler's.
            """)
        }
    }

    func testStateIsNotSharedValueType() throws {
        let eventLoop = app.eventLoopGroup.next()

        let count: Int = 0

        let assertion = { (number: Int) in  XCTAssertEqual(number, count) }

        let handler = TestHandler()

        let syncGuard = { AnyGuard(CountGuard(callback: assertion)) }
        let asyncGuard = { AnyGuard(AsyncCountGuard(callback: assertion, eventLoop: eventLoop)) }
        
        let endpoint = handler.mockEndpoint(
            guards: [syncGuard, asyncGuard],
            responseTransformers: [ { CountTransformer() } ])

        let exporter = MockExporter<String>()

        let context1 = endpoint.createConnectionContext(for: exporter)
        let context2 = endpoint.createConnectionContext(for: exporter)

        _ = try context1.handle(request: "Example Request", eventLoop: eventLoop)
                .wait()

        // Call on this context should not be influenced by previous call. Thus do not increase `count`.
        let response = try context2.handle(request: "Example Request", eventLoop: eventLoop)
                .wait()

        switch response.typed(String.self) {
        case .some(.final("")):
            break
        default:
            XCTFail("""
                Return value did not match expected value.
                This is most likely caused by the default value of 'Parameter' being shared across 'Handler's.
            """)
        }
    }
    
    func testStateIsNotSharedDifferentExportersValueType() throws {
        let eventLoop = app.eventLoopGroup.next()

        let count: Int = 0

        let assertion = { (number: Int) in  XCTAssertEqual(number, count) }

        let handler = TestHandler()

        let syncGuard = { AnyGuard(CountGuard(callback: assertion)) }
        let asyncGuard = { AnyGuard(AsyncCountGuard(callback: assertion, eventLoop: eventLoop)) }
        
        let endpoint = handler.mockEndpoint(
            guards: [syncGuard, asyncGuard],
            responseTransformers: [ { CountTransformer() } ])

        let exporter1 = MockExporter<String>()
        let exporter2 = MockExporter<String>()

        let context1 = endpoint.createConnectionContext(for: exporter1)
        let context2 = endpoint.createConnectionContext(for: exporter2)

        _ = try context1.handle(request: "Example Request", eventLoop: eventLoop)
                .wait()

        // Call on this context should not be influenced by previous call. Thus do not increase `count`.
        let response = try context2.handle(request: "Example Request", eventLoop: eventLoop)
                .wait()

        switch response.typed(String.self) {
        case .some(.final("")):
            break
        default:
            XCTFail("""
                Return value did not match expected value.
                This is most likely caused by the default value of 'Parameter' being shared across 'Handler's.
            """)
        }
    }
}
