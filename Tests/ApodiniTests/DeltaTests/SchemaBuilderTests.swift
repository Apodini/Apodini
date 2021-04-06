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

        let accountSchemaName = try XCTUnwrap(builder.build(for: Account.self))

        let builderSchemas = builder.schemas

        let primitives = builderSchemas.filter { $0.properties.isEmpty }

        XCTAssertEqual(primitives, [.primitive(type: .int), .primitive(type: .string), .primitive(type: .float), .primitive(type: .uuid)])

        XCTAssertEqual(builderSchemas.filter { $0.isEnumeration.value }.count, 1)

        let enumSchema = try XCTUnwrap(builderSchemas.first { $0.schemaName == .init("ApodiniTests.SchemaBuilderTests.Direction") })
        let expectedEnumSchema: Schema = .enumeration(
            schemaName: .init("ApodiniTests.SchemaBuilderTests.Direction"),
            cases: "right", "left"
        )
        XCTAssertEqual(enumSchema, expectedEnumSchema)

        let accountSchema = try XCTUnwrap(builderSchemas.first { $0.schemaName == accountSchemaName })
        let expectedAccountResult: Schema = .complex(
            schemaName: .init("ApodiniTests.SchemaBuilderTests.Account"),
            properties: [
                .property(named: "car", offset: 1, type: .exactlyOne, schemaName: .init("ApodiniTests.SchemaBuilderTests.Car")),
                .property(named: "amount", offset: 2, type: .optional, schemaName: .init("Swift.Int")),
                .property(named: "names", offset: 3, type: .array, schemaName: .init("Swift.String")),
                .property(named: "dict", offset: 4, type: .dictionary(key: .float), schemaName: .init("ApodiniTests.SchemaBuilderTests.User")),
                .property(named: "direction", offset: 5, type: .array, schemaName: .init("ApodiniTests.SchemaBuilderTests.Direction"))
            ])

        XCTAssertEqual(accountSchema, expectedAccountResult)
    }
}
