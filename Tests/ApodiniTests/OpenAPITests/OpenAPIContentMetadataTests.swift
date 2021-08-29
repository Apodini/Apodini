//
// Created by Andreas Bauer on 28.08.21.
//

import XCTest
import Apodini
@testable import ApodiniOpenAPI
import OpenAPIKit

struct HelloWorld: Content {
    var hello: String
    var magicNumber: Int?

    var origin: Origin?

    static var metadata: Metadata {
        Example(HelloWorld(hello: "World"))

        Example(for: \.magicNumber, 42, propertyName: "magicNumber")

        Example(for: \.origin, Origin(country: "de", language: .init(name: "Deutsch")), propertyName: "origin")

        Description("This type represents a Hello World message with some extra goodies.")

        MarkDeprecated()
    }
}

struct Origin: Content {
    var country: String
    var language: Language
}

struct Language: Content {
    var name: String
}

final class OpenAPIContentMetadataTests: XCTestCase {
    func XCTAssertJSONSchemeEqual(_ received: JSONSchema, _ expected: JSONSchema) throws {
        // we need to encode to JSON as AnyCodable just always returns false for non standard types
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes] // TODO adjust

        let receivedJSON = try XCTUnwrap(String(data: encoder.encode(received), encoding: .utf8))
        let expectedJSON = try XCTUnwrap(String(data: encoder.encode(expected), encoding: .utf8))

        print(receivedJSON)

        XCTAssertEqual(receivedJSON, expectedJSON)
    }

    // TODO all vendorextensions just fail (AnyCodable!!!)
    func testExampleMetadata() throws {
        // TODO componentKey stuff thingy with "unknownContext" in name!

        let componentBuilder = OpenAPIComponentsObjectBuilder()

        // TODO test buildResponse?
        let helloWorldSchema = try XCTUnwrap(try? componentBuilder.buildSchema(for: HelloWorld.self))
            .rootDereference(in: componentBuilder.componentsObject)

        let originSchema = try XCTUnwrap(try? componentBuilder.componentsObject.schemas[.init(stringLiteral: "Origin")])
            .rootDereference(in: componentBuilder.componentsObject)
        let languageSchema = try XCTUnwrap(try? componentBuilder.componentsObject.schemas[.init(stringLiteral: "Language")])
            .rootDereference(in: componentBuilder.componentsObject)

        // TODO ensure that the regaulr origin is not modified

        // TODO remove
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        print(String(data: try encoder.encode(componentBuilder.componentsObject), encoding: .utf8)!)

        let originProperties: [String: JSONSchema] = [
            "country": .string(),
            "language": .reference(.component(named: "Language"))
        ]

        let expectedLanguage = JSONSchema.object(properties: ["name": .string()])

        let expectedOrigin = JSONSchema.object(
            properties: originProperties
        )

        let expectedHelloWorld = JSONSchema.object(
            deprecated: true,
            description: "This type represents a Hello World message with some extra goodies.",
            properties: [
                "hello": .string(),
                "magicNumber": .integer(
                    required: false,
                    example: AnyCodable(42)
                ),
                "origin": .object(
                    required: true, // TODO somethings faulty, required is wrongfully true from the beginning on!
                    properties: originProperties,
                    example: AnyCodable.fromComplex(Origin(country: "de", language: .init(name: "Deutsch")))
                )
            ],
            example: AnyCodable.fromComplex(HelloWorld(hello: "World"))
        )

        // test that the "Hello World" scheme was modified according the Metadata
        try XCTAssertJSONSchemeEqual(helloWorldSchema, expectedHelloWorld)

        // test that the modifications made to origin property in "Hello World" didn't affect the globally defined schema
        try XCTAssertJSONSchemeEqual(originSchema, expectedOrigin)
        // out of completeness, verify `Language`
        try XCTAssertJSONSchemeEqual(languageSchema, expectedLanguage)
    }
}
