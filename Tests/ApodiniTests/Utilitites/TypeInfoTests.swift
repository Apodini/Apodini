//
//  TypeInfoTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/13/21.
//

import XCTest
@testable import Apodini
import ApodiniUtils

class TypeInfoTests: ApodiniTests {
    func testIsOptional() {
        /// A custom type
        struct Test {}

        XCTAssertEqual(isOptional(String.self), false)
        XCTAssertEqual(isOptional(Int.self), false)
        XCTAssertEqual(isOptional(Test.self), false)
        XCTAssertEqual(isOptional(Optional<Test>.self), true)
        XCTAssertEqual(isOptional(String?.self), true)
        XCTAssertEqual(isOptional(String??.self), true)
        XCTAssertEqual(isOptional(String???.self), true)
        XCTAssertEqual(isOptional(Never.self), false)
        
        // A case that should throw an error in isOptional
        XCTAssertEqual(isOptional((() -> Void).self), false)
    }

    func testIsEnum() {
        /// A custom type
        enum Test {
            case unit
            case integration
            case system
        }

        XCTAssertEqual(isEnum(Test.self), true)
        XCTAssertEqual(isEnum(Int.self), false)
        XCTAssertEqual(isEnum(Optional<Test>.self), false)
        XCTAssertEqual(isEnum(String?.self), false)
        XCTAssertEqual(isEnum(Never.self), true)

        // A case that should throw an error in isEnum
        XCTAssertEqual(isEnum((() -> Void).self), false)
    }
    
    func testDescription() {
        let parameter = Parameter<String>()
        XCTAssertEqual(ApodiniUtils.mangledName(of: type(of: parameter)), "Parameter")
        
        let array = ["Paul"]
        XCTAssertEqual(ApodiniUtils.mangledName(of: type(of: array)), "Array")
        
        let string = "Paul"
        XCTAssertEqual(ApodiniUtils.mangledName(of: type(of: string)), "String")
        
        XCTAssertEqual(ApodiniUtils.mangledName(of: (() -> Void).self), "() -> ()")
        XCTAssertEqual(ApodiniUtils.mangledName(of: ((String) -> (Int)).self), "(String) -> Int")
    }
    
    func testIsSupportedScalarType() {
        XCTAssertEqual(isSupportedScalarType(Int32.self), true)
        XCTAssertEqual(isSupportedScalarType(Int64.self), true)
        XCTAssertEqual(isSupportedScalarType(UInt32.self), true)
        XCTAssertEqual(isSupportedScalarType(UInt64.self), true)
        XCTAssertEqual(isSupportedScalarType(Bool.self), true)
        XCTAssertEqual(isSupportedScalarType(String.self), true)
        XCTAssertEqual(isSupportedScalarType(Double.self), true)
        XCTAssertEqual(isSupportedScalarType(Float.self), true)
        
        struct EmptyTest {}
        struct Test {
            var test: String
        }
        
        XCTAssertEqual(isSupportedScalarType(Never.self), false)
        XCTAssertEqual(isSupportedScalarType(Test.self), false)
        XCTAssertEqual(isSupportedScalarType(EmptyTest.self), false)
    }
}
