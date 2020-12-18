//
//  ThreadSafetyTests.swift
//  
//
//  Created by Max Obermeier on 24.11.20.
//


import XCTest
import NIO
import Vapor
import Fluent
@testable import Apodini


final class ThreadSafetyTests: ApodiniTests {
    struct Greeter: Component {
        @Parameter var id: String

        func handle() -> String {
            return id
        }
    }
    
    func testRequestInjectableUnlimitedConcurrency() throws {
        let greeter = Greeter()
        var count = 1000
        let countMutex = NSLock()
        
        DispatchQueue.concurrentPerform(iterations: count) { _ in
            let id = randomString(length: 40)
            let request = Request(application: app, collectedBody: ByteBuffer(string: id), on: app.eventLoopGroup.next())
            let restRequest = RESTRequest(request) { _ in
                return id
            }

            do {
                let response = try restRequest
                    .enterRequestContext(with: greeter) { component in
                        component.handle().encodeResponse(for: request)
                    }
                    .wait()
                let responseData = try XCTUnwrap(response.body.data)
                
                XCTAssert(String(data: responseData, encoding: .utf8) == id)
                
                countMutex.lock()
                count -= 1
                countMutex.unlock()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertEqual(count, 0)
    }
    
    func testRequestInjectableSingleThreaded() throws {
        let greeter = Greeter()
        var count = 1000
        
        for _ in 0..<count {
            let id = randomString(length: 40)
            let request = Request(application: app, collectedBody: ByteBuffer(string: id), on: app.eventLoopGroup.next())
            let restRequest = RESTRequest(request) { _ in
                return id
            }

            do {
                let response = try restRequest
                    .enterRequestContext(with: greeter) { component in
                        component.handle().encodeResponse(for: request)
                    }
                    .wait()
                let responseData = try XCTUnwrap(response.body.data)
                
                XCTAssert(String(data: responseData, encoding: .utf8) == id)
                
                count -= 1
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertEqual(count, 0)
    }
    
    // swiftlint:disable force_unwrapping
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    // swiftlint:enable force_unwrapping
}
