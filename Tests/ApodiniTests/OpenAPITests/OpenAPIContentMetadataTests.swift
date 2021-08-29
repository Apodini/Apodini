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

        let num_42: Int? = 42

        let expectedHelloWorld = JSONSchema.object(
            deprecated: true,
            description: "This type represents a Hello World message with some extra goodies.",
            properties: [
                "hello": .string(),
                "magicNumber": .integer(
                    required: false,
                    example: AnyCodable.fromComplex(num_42)
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
}
