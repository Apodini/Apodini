//
//  TypeInfoTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/13/21.
//

import XCTest
@testable import Apodini

class TypeInfoTests: ApodiniTests {
    func testIsOptional() {
        /// A custom type
        struct Test {}

        XCTAssertEqual(isOptional(String.self), false)
        XCTAssertEqual(isOptional(Int.self), false)
        XCTAssertEqual(isOptional(Test.self), false)
        XCTAssertEqual(isOptional(Optional<Test>.self), true)
        XCTAssertEqual(isOptional(Optional<Test>.self), true)
        XCTAssertEqual(isOptional(String?.self), true)
        XCTAssertEqual(isOptional(String??.self), true)
        XCTAssertEqual(isOptional(String???.self), true)
        XCTAssertEqual(isOptional(Never.self), false)
        
        // A case that should throw an error in isOptional
        XCTAssertEqual(isOptional((() -> Void).self), false)
    }
    
    func testDescription() {
        let parameter = Parameter<String>()
        XCTAssertEqual(Apodini.mangledName(of: type(of: parameter)), "Parameter")
        
        let array = ["Paul"]
        XCTAssertEqual(Apodini.mangledName(of: type(of: array)), "Array")
        
        let string = "Paul"
        XCTAssertEqual(Apodini.mangledName(of: type(of: string)), "String")
        
        XCTAssertEqual(Apodini.mangledName(of: (() -> Void).self), "() -> ()")
        XCTAssertEqual(Apodini.mangledName(of: ((String) -> (Int)).self), "(String) -> Int")
    }
}
