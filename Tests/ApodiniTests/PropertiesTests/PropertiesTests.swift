//
//  PropertiesTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/2/21.
//

import XCTest
@testable import Apodini


final class PropertiesTests: ApodiniTests {
    func testTypedPorperties() throws {
        let number = Parameter<Int>(wrappedValue: 42)
        let otherNumber = Parameter<Int>(wrappedValue: 0)
        let string = Parameter<String>(wrappedValue: "Paul")
        let environment = Apodini.Environment(\.database)
        
        let elements: [(String, Property)] = [
            ("number", number),
            ("anOtherNumber", otherNumber),
            ("string", string),
            ("environment", environment)
        ]
        
        let properties = Apodini.Properties()
            .with(number, named: "number")
            .with(otherNumber, named: "anOtherNumber")
            .with(string, named: "string")
            .with(environment, named: "environment")
        
        XCTAssertEqual(properties.wrappedValue.count, elements.count)
        
        for (key, value) in elements {
            let typeOfValue = type(of: value).self
            let typeOfWrappedValue = type(of: try XCTUnwrap(properties.wrappedValue[key])).self
            XCTAssert(typeOfValue == typeOfWrappedValue)
        }
                
        let numberParameters = properties.typed(Parameter<Int>.self)
        XCTAssertEqual(numberParameters.count, 2)
        XCTAssertEqual(numberParameters["number"]?.defaultValue?(), (elements[0].1 as? Parameter<Int>)?.defaultValue?())
        XCTAssertEqual(numberParameters["anOtherNumber"]?.defaultValue?(), (elements[1].1 as? Parameter<Int>)?.defaultValue?())
        
        let stringParameters = properties.typed(Parameter<String>.self)
        XCTAssertEqual(stringParameters.count, 1)
        stringParameters.forEach {
            XCTAssertEqual($0.0, elements[2].0)
            XCTAssertEqual($0.1.defaultValue?(), (elements[2].1 as? Parameter<String>)?.defaultValue?())
        }
    }
}
