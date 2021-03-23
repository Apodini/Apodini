//
//  File.swift
//  
//
//  Created by Eldi Cano on 21.03.21.
//

import Foundation
import XCTest
@testable import ApodiniDelta

final class SchemaBuilderTests: XCTestCase {

    struct Car: Encodable {
        let name: String
        let plateNumber: Int?
    }

    struct User: Encodable {
        let surname: String
        let uuid: UUID
    }

    enum Direction: String, Encodable {
        case right
        case left
    }

    struct Account: Encodable {
        let car: Car
        let amount: Int?
        let names: [String]
        let dict: [Float: User]
        let direction: [Direction]
    }

    func testSchemaBuilder() throws {
        var builder = SchemaBuilder()

        let accountReference = try XCTUnwrap(builder.build(for: Account.self, root: true))

        let builderSchemas = builder.schemas

        let primitives = builderSchemas.filter { $0.properties.isEmpty }

        XCTAssertEqual(primitives, [.primitive(type: .int), .primitive(type: .string), .primitive(type: .float), .primitive(type: .uuid)])

        XCTAssertEqual(builderSchemas.filter { $0.isEnumeration }.count, 1)

        let enumSchema = try XCTUnwrap(builderSchemas.first { $0.reference == .reference("Direction") })
        let expectedEnumSchema: Schema = .enumeration(typeName: "Direction", cases: "right", "left")
        XCTAssertEqual(enumSchema, expectedEnumSchema)

        let accountSchema = try XCTUnwrap(builderSchemas.first { $0.reference == accountReference })
        let expectedAccountResult: Schema = .complex(
            typeName: "Account",
            properties: [
                .property(named: "car", offset: 1, type: .exactlyOne, reference: .reference("Car")),
                .property(named: "amount", offset: 2, type: .optional, reference: .reference("Int")),
                .property(named: "names", offset: 3, type: .array, reference: .reference("String")),
                .property(named: "dict", offset: 4, type: .dictionary(key: .float), reference: .reference("User")),
                .property(named: "direction", offset: 5, type: .array, reference: .reference("Direction"))
            ])

        XCTAssertEqual(accountSchema, expectedAccountResult)
    }
    
    func testPropertyTypeCodable() throws {
        let jsonEncoder = JSONEncoder()
        let jsonDecoder = JSONDecoder()
        
        let optional: PropertyType = .optional
        let optionalData = try jsonEncoder.encode(optional)
        let optionalDecoded = try jsonDecoder.decode(PropertyType.self, from: optionalData)
        XCTAssertEqual(optionalDecoded, optional)
        
        let exactlyOne: PropertyType = .exactlyOne
        let exactlyOneData = try jsonEncoder.encode(exactlyOne)
        let exactlyOneDecoded = try jsonDecoder.decode(PropertyType.self, from: exactlyOneData)
        XCTAssertEqual(exactlyOneDecoded, exactlyOne)
        
        let array: PropertyType = .array
        let arrayData = try jsonEncoder.encode(array)
        let arrayDecoded = try jsonDecoder.decode(PropertyType.self, from: arrayData)
        XCTAssertEqual(arrayDecoded, array)
        
        let bool: PropertyType = .dictionary(key: .bool)
        let data = try jsonEncoder.encode(bool)
        let dictionaryDecoded = try jsonDecoder.decode(PropertyType.self, from: data)
        XCTAssertEqual(bool, dictionaryDecoded)
        
        let uint: PropertyType = .dictionary(key: .uint)
        let uintData = try jsonEncoder.encode(uint)
        let uintDecoded = try jsonDecoder.decode(PropertyType.self, from: uintData)
        XCTAssertEqual(uint, uintDecoded)
    }
}
