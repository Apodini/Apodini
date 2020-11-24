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

@propertyWrapper
struct Atomic<Value> {
    private var mutex = NSRecursiveLock()
    private var _value: Value
  
    var wrappedValue: Value {
        get {
            return self.guard {
                return _value
            }
        }
        set {
            self.guard {
                _value = newValue
            }
        }
    }
    
    init(wrappedValue value: Value) {
        self._value = value
    }
}

extension Atomic {
    
    func `guard`<T>(_ closure: () throws  -> T) rethrows -> T {
        mutex.lock()
        defer { mutex.unlock() }
        return try closure()
    }
    
}

extension Atomic where Value: AdditiveArithmetic {

    static func +=(left: inout Self, right: Value) {
        left.guard {
            left._value += right
        }
    }
    
    static func -=(left: inout Self, right: Value) {
        left.guard {
            left._value -= right
        }
    }
}


final class ThreadSafetyTests: ApodiniTests {
    
    struct Greeter: Component {
            
        @Apodini.Request
        var req: Vapor.Request
        
        func handle() -> String {
            return req.body.string ?? "World"
        }
        
    }
    
    @Atomic var testRequestInjectableUnlimitedConcurrencyCount: Int = 1000
    
    func testRequestInjectableUnlimitedConcurrency() throws {
        let g = Greeter()
        
        DispatchQueue.concurrentPerform(iterations: testRequestInjectableUnlimitedConcurrencyCount) { _ in
            
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
                _testRequestInjectableUnlimitedConcurrencyCount -= 1
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertEqual(testRequestInjectableUnlimitedConcurrencyCount, 0)
    }
    
    @Atomic var testRequestInjectableSingleThreadedCount: Int = 1000
    
    func testRequestInjectableSingleThreaded() throws {
        let g = Greeter()
        
        for _ in 0..<testRequestInjectableSingleThreadedCount {
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
                _testRequestInjectableSingleThreadedCount -= 1
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertEqual(testRequestInjectableSingleThreadedCount, 0)
    }
    
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
