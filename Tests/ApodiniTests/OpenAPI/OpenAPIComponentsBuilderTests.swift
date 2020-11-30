//
//  OpenAPIComponentsBuilderTests.swift
//  
//
//  Created by Lorena Schlesinger on 29.11.20.
//

import XCTest
import Foundation
import OpenAPIKit
import Runtime
import NIO
@testable import Apodini

final class OpenAPIComponentsBuilderTests: XCTestCase {

    let someString = "Some String"
    let someInt = 42
    let someDouble = 42.0
    let someBool = true
    let someDict = ["someKey":"someValue"]
    let someArray = [1,2,3]
    let someEventLoop: EventLoopFuture<Int>? = nil
    let someEither: Either<Int, String> = .init("someString")
    let someOptional: String? = nil
    
    struct SomeStruct {
        var someProp = 4
    }
        
    struct GenericStruct<T> {
        var list: [T]
        var listLength: Int
    }
    
    struct SomeComplexStruct {
        var someStruct: SomeStruct
        var someNestedStruct: SomeNestedStruct
        var someNestedStruct2: SomeNestedStruct
        var someItems: GenericStruct<SomeStruct>
        
        struct SomeNestedStruct {
            let a = 123
            let b: String?
        }
    }
    
    func testTypeInfoIsWrapperType() {
        var info = try! typeInfo(of: type(of: someString))
        XCTAssertEqual(info.isWrapperType, false)
        
        info = try! typeInfo(of: type(of: someInt))
        XCTAssertEqual(info.isWrapperType, false)
        
        info = try! typeInfo(of: type(of: someDouble))
        XCTAssertEqual(info.isWrapperType, false)
        
        info = try! typeInfo(of: type(of: someBool))
        XCTAssertEqual(info.isWrapperType, false)
        
        info = try! typeInfo(of: type(of: someArray))
        XCTAssertEqual(info.isWrapperType, false)
        
        info = try! typeInfo(of: type(of: SomeStruct()))
        XCTAssertEqual(info.isWrapperType, false)
        
        info = try! typeInfo(of: type(of: someDict))
        XCTAssertEqual(info.isWrapperType, false)
        
        info = try! typeInfo(of: type(of: someEventLoop))
        XCTAssertEqual(info.isWrapperType, true)
        
        info = try! typeInfo(of: type(of: someEither))
        XCTAssertEqual(info.isWrapperType, true)
        
        info = try! typeInfo(of: type(of: someOptional))
        XCTAssertEqual(info.isWrapperType, true)
    }
    
    func testTypeInfoIsPrimitive() {
        var info = try! typeInfo(of: type(of: someString))
        XCTAssertEqual(info.isPrimitive, true)
        
        info = try! typeInfo(of: type(of: someInt))
        XCTAssertEqual(info.isPrimitive, true)
        
        info = try! typeInfo(of: type(of: someDouble))
        XCTAssertEqual(info.isPrimitive, true)
        
        info = try! typeInfo(of: type(of: someBool))
        XCTAssertEqual(info.isPrimitive, true)
        
        info = try! typeInfo(of: type(of: someArray))
        XCTAssertEqual(info.isPrimitive, false)
        
        info = try! typeInfo(of: type(of: SomeStruct()))
        XCTAssertEqual(info.isPrimitive, false)
        
        info = try! typeInfo(of: type(of: someDict))
        XCTAssertEqual(info.isPrimitive, false)
        
        info = try! typeInfo(of: type(of: someEventLoop))
        XCTAssertEqual(info.isPrimitive, false)
        
        info = try! typeInfo(of: type(of: someEither))
        XCTAssertEqual(info.isPrimitive, false)
        
        info = try! typeInfo(of: type(of: someOptional))
        XCTAssertEqual(info.isPrimitive, false)
    }
    
    func testTypeInfoIsArray() {
        let info = try! typeInfo(of: type(of: someArray))
        XCTAssertEqual(info.isArray, true)
    }
    
    func testTypeInfoIsDictionary() {
        let info = try! typeInfo(of: type(of: someDict))
        XCTAssertEqual(info.isDictionary, true)
    }
    
    func testBuildSchemaPrimitive() {
        let componentsBuilder = OpenAPIComponentsBuilder()
        
        // add primitive type (will not be added to components map, but defined inline)
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: type(of: someString)))
        let schema = try! componentsBuilder.buildSchema(for: type(of: someString))
        XCTAssertEqual(schema, JSONSchema.string())
        XCTAssertEqual(componentsBuilder.components.schemas.count, 0)
        XCTAssertEqual(componentsBuilder.components, .noComponents)
    }
    
    func testBuildSchemaComplex_referenceExists() {
        let componentsBuilder = OpenAPIComponentsBuilder()
        
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: SomeComplexStruct.self))
        _ = try! componentsBuilder.buildSchema(for: SomeComplexStruct.self)
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: "\(SomeComplexStruct.self)")).dereferenced(in: componentsBuilder.components))
        XCTAssertEqual(componentsBuilder.components.schemas.count, 4)
    }
    
    func testBuildSchemaComplex_schemasCorrect() throws {
        let componentsBuilder = OpenAPIComponentsBuilder()
        _ = try componentsBuilder.buildSchema(for: SomeComplexStruct.self)
        
        let ref1 = try componentsBuilder.components.reference(named: "SomeStruct", ofType: JSONSchema.self)
        let ref2 = try componentsBuilder.components.reference(named: "SomeNestedStruct", ofType: JSONSchema.self)
        let ref3 = try componentsBuilder.components.reference(named: "GenericStruct", ofType: JSONSchema.self)
        let ref4 = try componentsBuilder.components.reference(named: "SomeComplexStruct", ofType: JSONSchema.self)
        
        XCTAssertEqual(componentsBuilder.components[ref1], .object(properties: ["someProp": .integer()]))
        XCTAssertEqual(componentsBuilder.components[ref2], .object(
                        properties: [
                            "a": .integer(),
                            "b": .string()]))
        XCTAssertEqual(componentsBuilder.components[ref3], .object(
                        properties: [
                            "list": .array(items: .reference(.component(named: "SomeStruct"))),
                            "listLength": .integer()]))
        XCTAssertEqual(componentsBuilder.components[ref4], .object(properties: [
            "someNestedStruct2": .reference(.component(named: "SomeNestedStruct")),
            "someItems": .reference(.component(named: "GenericStruct")),
            "someStruct" : .reference(.component(named: "SomeStruct")),
            "someNestedStruct": .reference(.component(named: "SomeNestedStruct"))
            ]))
    }
}
