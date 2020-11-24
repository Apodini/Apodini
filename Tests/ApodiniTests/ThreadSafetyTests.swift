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
            
        @Apodini.Request
        var req: Vapor.Request
        
        func handle() -> String {
            return req.body.string ?? "World"
        }
        
    }
    
    func testRequestInjectableUnlimitedConcurrency() throws {
        let g = Greeter()
        var count = 1000
        var countMutex = NSLock()
        
        DispatchQueue.concurrentPerform(iterations: count) { _ in
            
            let id = randomString(length: 40)
            let request = Request(application: app, collectedBody: ByteBuffer(string: id), on: app.eventLoopGroup.next())
            
            do {
                let response = try request
                    .enterRequestContext(with: g) { component in
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
        let g = Greeter()
        var count = 1000
        
        for _ in 0..<count {
            let id = randomString(length: 40)
            let request = Request(application: app, collectedBody: ByteBuffer(string: id), on: app.eventLoopGroup.next())
            
            do {
                let response = try request
                    .enterRequestContext(with: g) { component in
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
    
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
