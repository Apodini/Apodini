//
//  FieldKeyProperty.swift
//  
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

@testable import Apodini
@testable import ApodiniDatabase
import XCTest


final class DatabaseInjectionContextTests: XCTApodiniDatabaseBirdTest {
    func testDatabaseInjectionContextCreation() throws {
        XCTFail()
        
//        let fieldKeyProperties = MockModel.fieldKeyProperties
//            .map {
//                ($0.key, $0.property)
//            }
//
//        XCTAssertEqual(fieldKeyProperties.count, 8)
//
//        let properties = Dictionary(uniqueKeysWithValues: fieldKeyProperties)
//
//        try testParameter(
//            properties[.id],
//            expectedType: Optional<UUID>.self,
//            name: "id"
//        )
//
//        try testParameter(
//            properties["uint8Column"],
//            expectedType: Optional<UInt8>.self,
//            name: "uint8"
//        )
//
//        try testParameter(
//            properties[.string("stringColumn")],
//            expectedType: Optional<String>.self,
//            name: "string"
//        )
//
//        try testParameter(
//            properties[.string("int64Column")],
//            expectedType: Optional<Int64>.self,
//            name: "int64"
//        )
//
//        try testParameter(
//            properties[.string("boolColumn")],
//            expectedType: Optional<Bool>.self,
//            name: "bool"
//        )
//
//        try testParameter(
//            properties[.string("floatColumn")],
//            expectedType: Optional<Float>.self,
//            name: "float"
//        )
//
//        try testParameter(
//            properties[.string("customLosslessStringConvertibleStructColumn")],
//            expectedType: Optional<MockModel.CustomLosslessStringConvertibleStruct>.self,
//            name: "customLosslessStringConvertibleStruct"
//        )
//
//        try testParameter(
//            properties[.string("customLosslessStringConvertibleEnumColumn")],
//            expectedType: Optional<MockModel.CustomLosslessStringConvertibleEnum>.self,
//            name: "customLosslessStringConvertibleEnum"
//        )
    }
    
    private func testParameter<T: Decodable>(
        _ property: Apodini.Property?,
        expectedType: T.Type = T.self,
        name: String)
    throws {
        let parameter = try XCTUnwrap(property as? Parameter<T>)
        
        XCTAssertEqual(parameter.name, name)
        XCTAssertEqual(parameter.options.option(for: .http), .query)
    }
}
