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
        var codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
            fatalError("Decoding started: KeyedEncodingContainer")
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            fatalError("Decoding started: UnkeyedContainer")
        }
        
        func singleValueContainer() -> SingleValueEncodingContainer {
            ActionTests.actionExpectation?.fulfill()
            fatalError("Decoding started: SingleValueContainer")
        }
    }
    
    func testActionEncoding() throws {
        let nothingAction = Action<Never>.nothing
        XCTAssertRuntimeFailure(try? nothingAction.encode(to: TextEncoder()))
        
        let endAction = Action<Never>.end
        XCTAssertRuntimeFailure(try? endAction.encode(to: TextEncoder()))
        
        ActionTests.actionExpectation = self.expectation(description: "Decoding Started")
        let sendAction = Action.send("Paul")
        XCTAssertRuntimeFailure(try? sendAction.encode(to: TextEncoder()))
        waitForExpectations(timeout: 0, handler: nil)
        
        ActionTests.actionExpectation = self.expectation(description: "Decoding Started")
        let finalAction = Action.final("Paul")
        XCTAssertRuntimeFailure(try? finalAction.encode(to: TextEncoder()))
        waitForExpectations(timeout: 0, handler: nil)
    }
}
