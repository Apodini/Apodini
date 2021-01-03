//
//  ActionTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/3/21.
//

import Apodini
import XCTest


final class ActionTests: XCTestCase {
    private static var actionExpectation: XCTestExpectation?
    
    
    struct TextEncoder: Encoder {
        struct TestEncoderSingleValueContainer: SingleValueEncodingContainer {
            var codingPath: [CodingKey]
            
            mutating func encodeNil() throws { }
            mutating func encode(_ value: Bool) throws { }
            mutating func encode(_ value: String) throws {
                XCTAssertEqual("Paul", value)
                ActionTests.actionExpectation?.fulfill()
            }
            mutating func encode(_ value: Double) throws { }
            mutating func encode(_ value: Float) throws { }
            mutating func encode(_ value: Int) throws { }
            mutating func encode(_ value: Int8) throws { }
            mutating func encode(_ value: Int16) throws { }
            mutating func encode(_ value: Int32) throws { }
            mutating func encode(_ value: Int64) throws { }
            mutating func encode(_ value: UInt) throws { }
            mutating func encode(_ value: UInt8) throws { }
            mutating func encode(_ value: UInt16) throws { }
            mutating func encode(_ value: UInt32) throws { }
            mutating func encode(_ value: UInt64) throws { }
            mutating func encode<T>(_ value: T) throws where T : Encodable { }
        }
        
        var codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
            fatalError("Decoding started: KeyedEncodingContainer")
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            fatalError("Decoding started: UnkeyedContainer")
        }
        
        func singleValueContainer() -> SingleValueEncodingContainer {
            TestEncoderSingleValueContainer(codingPath: codingPath)
        }
    }
    
    func testActionEncoding() throws {
        let nothingAction = Action<Never>.nothing
        XCTAssertRuntimeFailure(try? nothingAction.encode(to: TextEncoder()))
        
        let endAction = Action<Never>.end
        XCTAssertRuntimeFailure(try? endAction.encode(to: TextEncoder()))
        
        ActionTests.actionExpectation = self.expectation(description: "Decoding Started")
        let sendAction = Action.send("Paul")
        try? sendAction.encode(to: TextEncoder())
        waitForExpectations(timeout: 0, handler: nil)
        
        ActionTests.actionExpectation = self.expectation(description: "Decoding Started")
        let finalAction = Action.final("Paul")
        try? finalAction.encode(to: TextEncoder())
        waitForExpectations(timeout: 0, handler: nil)
    }
}
