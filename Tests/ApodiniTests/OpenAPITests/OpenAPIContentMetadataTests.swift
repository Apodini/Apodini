//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import Apodini
@testable import ApodiniOpenAPI
import OpenAPIKit

struct HelloWorld: Content {
    var hello: String
    var magicNumber: Int?

    var origin: Origin?

    var requiredOrigin: Origin

    static var metadata: Metadata {
        Example(HelloWorld(hello: "World", requiredOrigin: Origin.default))

        Example(for: \.magicNumber, 42, propertyName: "magicNumber")

        Example(for: \.requiredOrigin, Origin.default, propertyName: "requiredOrigin")

        Description("This type represents a Hello World message with some extra goodies.")

        MarkDeprecated()
    }
}

struct Origin: Content {
    static var `default` = Origin(country: "de", language: .init(name: "Deutsch"))

    var country: String
    var language: Language
}

struct Language: Content {
    var name: String
}

struct TypeWithStrings: Content {
    var name: String

    static var metadata: Metadata {
        MinLength(of: \.name, is: 2, propertyName: "name")
        MaxLength(of: \.name, is: 20, propertyName: "name")
        Pattern(of: \.name, is: "some regex", propertyName: "name")
    }
}

struct TypeWithInts: Content {
    var int: Int

    var int8: Int8
    var int16: Int16
    var int32: Int32
    var int64: Int64

    var uint8: UInt8
    var uint16: UInt16
    var uint32: UInt32
    var uint64: UInt64

    var float: Float
    var double: Double

    static var metadata: Metadata {
        MultipleOf(of: \.int, is: 2, propertyName: "int")
        Minimum(of: \.int, is: 2, propertyName: "int")
        Maximum(of: \.int, is: 4, propertyName: "int")

        // intXX
        Block {
            MultipleOf(of: \.int8, is: 2, propertyName: "int8")
            Minimum(of: \.int8, is: 2, propertyName: "int8")
            Maximum(of: \.int8, is: 4, propertyName: "int8")

            MultipleOf(of: \.int16, is: 2, propertyName: "int16")
            Minimum(of: \.int16, is: 2, propertyName: "int16")
            Maximum(of: \.int16, is: 4, propertyName: "int16")

            MultipleOf(of: \.int32, is: 2, propertyName: "int32")
            Minimum(of: \.int32, is: 2, propertyName: "int32")
            Maximum(of: \.int32, is: 4, propertyName: "int32")

            MultipleOf(of: \.int64, is: 2, propertyName: "int64")
            Minimum(of: \.int64, is: 2, propertyName: "int64")
            Maximum(of: \.int64, is: 4, propertyName: "int64")
        }

        // uintxx
        Block {
            MultipleOf(of: \.uint8, is: 2, propertyName: "uint8")
            Minimum(of: \.uint8, is: 2, propertyName: "uint8")
            Maximum(of: \.uint8, is: 4, propertyName: "uint8")

            MultipleOf(of: \.uint16, is: 2, propertyName: "uint16")
            Minimum(of: \.uint16, is: 2, propertyName: "uint16")
            Maximum(of: \.uint16, is: 4, propertyName: "uint16")

            MultipleOf(of: \.uint32, is: 2, propertyName: "uint32")
            Minimum(of: \.uint32, is: 2, propertyName: "uint32")
            Maximum(of: \.uint32, is: 4, propertyName: "uint32")

            MultipleOf(of: \.uint64, is: 2, propertyName: "uint64")
            Minimum(of: \.uint64, is: 2, propertyName: "uint64")
            Maximum(of: \.uint64, is: 4, propertyName: "uint64")
        }


        MultipleOf(of: \.float, is: 2, propertyName: "float")
        Minimum(of: \.float, is: 2, propertyName: "float")
        Maximum(of: \.float, is: 4, propertyName: "float")

        MultipleOf(of: \.double, is: 2, propertyName: "double")
        Minimum(of: \.double, is: 2, propertyName: "double")
        Maximum(of: \.double, is: 4, propertyName: "double")
    }
}

final class OpenAPIContentMetadataTests: XCTestCase {
    func XCTAssertJSONSchemeEqual(_ received: JSONSchema, _ expected: JSONSchema) {
        XCTAssert(received <=> expected, "'\(received)' is not equal to '\(expected)'")
    }

    func testExampleMetadata() throws {
        let componentBuilder = OpenAPIComponentsObjectBuilder()

        let helloWorldSchema = try XCTUnwrap(try? componentBuilder.buildSchema(for: HelloWorld.self))
            .rootDereference(in: componentBuilder.componentsObject)

        let originSchema = try XCTUnwrap(componentBuilder.componentsObject.schemas[.init(stringLiteral: "Origin")])
            .rootDereference(in: componentBuilder.componentsObject)
        let languageSchema = try XCTUnwrap(componentBuilder.componentsObject.schemas[.init(stringLiteral: "Language")])
            .rootDereference(in: componentBuilder.componentsObject)

        let originProperties: [String: JSONSchema] = [
            "country": .string(),
            "language": .reference(.component(named: "Language"))
        ]

        let expectedLanguage = JSONSchema.object(properties: ["name": .string()])

        let expectedOrigin = JSONSchema.object(
            properties: originProperties
        )

        let num42: Int? = 42

        let expectedHelloWorld = JSONSchema.object(
            deprecated: true,
            description: "This type represents a Hello World message with some extra goodies.",
            properties: [
                "hello": .string(),
                "magicNumber": .integer(
                    required: false,
                    example: AnyCodable.fromComplex(num42)
                ),
                "origin": .object(
                    required: false,
                    properties: originProperties
                ),
                "requiredOrigin": .object(
                    properties: originProperties,
                    example: AnyCodable.fromComplex(Origin.default)
                )
            ],
            example: AnyCodable.fromComplex(HelloWorld(hello: "World", requiredOrigin: Origin.default))
        )

        // test that the "Hello World" scheme was modified according the Metadata
        XCTAssertJSONSchemeEqual(helloWorldSchema, expectedHelloWorld)

        // test that the modifications made to origin property in "Hello World" didn't affect the globally defined schema
        XCTAssertJSONSchemeEqual(originSchema, expectedOrigin)
        // out of completeness, verify `Language`
        XCTAssertJSONSchemeEqual(languageSchema, expectedLanguage)
    }

    func testStringMetadata() throws {
        let componentBuilder = OpenAPIComponentsObjectBuilder()

        let schema = try XCTUnwrap(try? componentBuilder.buildSchema(for: TypeWithStrings.self))
            .rootDereference(in: componentBuilder.componentsObject)

        let expectedSchema = JSONSchema.object(
            properties: [
                "name": .string(
                    minLength: 2,
                    maxLength: 20,
                    pattern: "some regex"
                )
            ]
        )

        XCTAssertJSONSchemeEqual(schema, expectedSchema)
    }

    func testNumericMetadata() throws {
        let componentBuilder = OpenAPIComponentsObjectBuilder()

        let schema = try XCTUnwrap(try? componentBuilder.buildSchema(for: TypeWithInts.self))
            .rootDereference(in: componentBuilder.componentsObject)

        let expectedSchema = JSONSchema.object(
            properties: [
                "int": .integer(
                    multipleOf: 2,
                    maximum: (4, exclusive: false),
                    minimum: (2, exclusive: false)
                ),

                "int8": .integer(
                    format: .other("int8"),
                    multipleOf: 2,
                    maximum: (4, exclusive: false),
                    minimum: (2, exclusive: false)
                ),
                "int16": .integer(
                    format: .other("int16"),
                    multipleOf: 2,
                    maximum: (4, exclusive: false),
                    minimum: (2, exclusive: false)
                ),
                "int32": .integer(
                    format: .int32,
                    multipleOf: 2,
                    maximum: (4, exclusive: false),
                    minimum: (2, exclusive: false)
                ),
                "int64": .integer(
                    format: .int64,
                    multipleOf: 2,
                    maximum: (4, exclusive: false),
                    minimum: (2, exclusive: false)
                ),

                "uint8": .integer(
                    format: .other("uint8"),
                    multipleOf: 2,
                    maximum: (4, exclusive: false),
                    minimum: (2, exclusive: false)
                ),
                "uint16": .integer(
                    format: .other("uint16"),
                    multipleOf: 2,
                    maximum: (4, exclusive: false),
                    minimum: (2, exclusive: false)
                ),
                "uint32": .integer(
                    format: .other("uint32"),
                    multipleOf: 2,
                    maximum: (4, exclusive: false),
                    minimum: (2, exclusive: false)
                ),
                "uint64": .integer(
                    format: .other("uint64"),
                    multipleOf: 2,
                    maximum: (4, exclusive: false),
                    minimum: (2, exclusive: false)
                ),

                "float": .number(
                    format: .float,
                    multipleOf: 2,
                    maximum: (4, exclusive: false),
                    minimum: (2, exclusive: false)
                ),
                "double": .number(
                    format: .double,
                    multipleOf: 2,
                    maximum: (4, exclusive: false),
                    minimum: (2, exclusive: false)
                )
            ]
        )

        XCTAssertJSONSchemeEqual(schema, expectedSchema)
    }
}
