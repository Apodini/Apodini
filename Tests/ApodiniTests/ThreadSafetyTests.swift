//
//  ThreadSafetyTests.swift
//  
//
//  Created by Max Obermeier on 24.11.20.
//


import XCTest
import XCTApodini
@testable import Apodini


final class ThreadSafetyTests: ApodiniTests {
    struct Greeter: Handler {
        @Parameter var id: String

        func handle() -> String {
            id
        }
    }
    
    func testRequestInjectableUnlimitedConcurrency() throws {
        let greeter = Greeter()
        var count = 1000
        let countMutex = NSLock()
        
        DispatchQueue.concurrentPerform(iterations: count) { _ in
            let id = randomString(length: 40)
            let request = MockRequest.createRequest(on: greeter, running: app.eventLoopGroup.next(), queuedParameters: id)
            var greeter = greeter
            Apodini.activate(&greeter)
            let response: String = try! request.enterRequestContext(with: greeter) { component in
                component.handle()
            }
            XCTAssertEqual(response, id)

            countMutex.lock()
            count -= 1
            countMutex.unlock()
        }
        
        XCTAssertEqual(count, 0)
    }
    
    func testRequestInjectableSingleThreaded() throws {
        var greeter = Greeter()
        var count = 1000
        
        for _ in 0..<count {
            let id = randomString(length: 40)
            let request = MockRequest.createRequest(on: greeter, running: app.eventLoopGroup.next(), queuedParameters: id)
            Apodini.activate(&greeter)
            let response: String = try request.enterRequestContext(with: greeter) { component in
                component.handle()
            }
            XCTAssertEqual(response, id)

            count -= 1
        }
        
        XCTAssertEqual(count, 0)
    }

    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        // swiftlint:disable:next force_unwrapping
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}
