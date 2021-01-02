//
//  ComponentTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/2/21.
//

@testable import Apodini
import XCTest


class ComponentTests: XCTestCase {
    func testAssertTypeIsStruct() throws {
        class TestClass {}
        XCTAssertRuntimeFailure(assertTypeIsStruct(TestClass.self))
        
        enum TestEnum {}
        XCTAssertRuntimeFailure(assertTypeIsStruct(TestEnum.self))
        
        struct TestStruct {}
        assertTypeIsStruct(TestStruct.self)
        
        XCTAssertRuntimeFailure(assertTypeIsStruct(Never.self))
        XCTAssertRuntimeFailure(assertTypeIsStruct((() -> Void).self))
    }
    
    func testTupleComponentErrors() throws {
        struct NoComponent {}
        let failingTupleComponent = TupleComponent((NoComponent(), NoComponent()))
        let syntaxTreeVisitor = SyntaxTreeVisitor()
        XCTAssertRuntimeFailure(failingTupleComponent.accept(syntaxTreeVisitor))
    }
}
