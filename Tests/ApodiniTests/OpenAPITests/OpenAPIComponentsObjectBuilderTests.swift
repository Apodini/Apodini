//
//  Created by Lorena Schlesinger on 29.11.20.
//

import XCTest
import Foundation
import NIO
@_implementationOnly import OpenAPIKit
@testable import Apodini

final class OpenAPIComponentsObjectBuilderTests: XCTestCase {
    let someString = "Some String"
    let someInt = 42
    let someDouble = 42.0
    let someBool = true
    let someDict = ["someKey": "someValue"]
    let someArray = [1, 2, 3]
    let someEventLoop: EventLoopFuture<Int>? = nil
    let someEither: Either<Int, String> = .init("someString")
    let someOptional: String? = nil
    let someOptionalUUID: UUID? = nil
    let someEnum = Test.system

    enum Test: String, Codable, CaseIterable {
        case unit
        case integration
        case system
    }

    struct SomeStruct: Encodable {
        var id: UUID?
        var someProp = 4
    }

    struct SomeStructWithEnum: Encodable {
        var someProp = 4
        var test: Test
    }

    struct GenericStruct<T>: Encodable where T: Encodable {
        var list: [T]
        var listLength: Int
    }

    struct SomeComplexStruct: Encodable {
        var someStruct: SomeStruct
        var someNestedStruct: SomeNestedStruct
        var someNestedStruct2: SomeNestedStruct
        var someItems: GenericStruct<SomeStruct>
    }
    
    struct SomeNestedStruct: Encodable {
        let someInt = 123
        let someString: String?
    }
    
    // add primitive types and non structs (will not be added to components map, but defined inline)
    func testBuildSchemaNonStructs() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()

        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: type(of: someString)))
        var schema = try componentsBuilder.buildSchema(for: type(of: someString))
        XCTAssertEqual(schema, .string())
        
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: type(of: someArray)))
        schema = try componentsBuilder.buildSchema(for: type(of: someArray))
        XCTAssertEqual(schema, .array(items: .init(.integer())))
        
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: type(of: someDict)))
        schema = try componentsBuilder.buildSchema(for: type(of: someDict))
        XCTAssertEqual(schema, .object(additionalProperties: .init(.string())))
        
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 0)
        XCTAssertEqual(componentsBuilder.componentsObject, .noComponents)

        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: type(of: someEnum)))
        schema = try componentsBuilder.buildSchema(for: type(of: someEnum))
        XCTAssertEqual(schema, .string(allowedValues: Test.allCases.map { .init($0.rawValue) }))

        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 0)
        XCTAssertEqual(componentsBuilder.componentsObject, .noComponents)
    }

    // add complex type (will be added to components map)
    func testBuildSchemaForResponses() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        XCTAssertNoThrow(try componentsBuilder.buildResponse(for: SomeStruct.self))
        let schema = try componentsBuilder.buildResponse(for: SomeStruct.self)
        
        XCTAssertThrowsError(try JSONSchema.reference(.component(named: "SomeStruct.self")).dereferenced(in: componentsBuilder.componentsObject))
        
        XCTAssertEqual(schema, .object(properties: [
            ResponseContainer.CodingKeys.data.rawValue: try componentsBuilder.buildSchema(for: SomeStruct.self),
            ResponseContainer.CodingKeys.links.rawValue: try componentsBuilder.buildSchema(for: ResponseContainer.Links.self)
        ]))
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 1)
    }

    func testBuildSchemaReference() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: SomeComplexStruct.self))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: "\(SomeComplexStruct.self)")).dereferenced(in: componentsBuilder.componentsObject))
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 4)
    }
    
    func testBuildSchemaArrayReference() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: Array<SomeStruct>.self))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: "\(SomeStruct.self)")).dereferenced(in: componentsBuilder.componentsObject))
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 1)
    }
    
    func testBuildSchemaOptionalReference() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: Optional<SomeStruct>.self))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: "\(SomeStruct.self)")).dereferenced(in: componentsBuilder.componentsObject))
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 1)
    }

    func testBuildSchemaEnumReference() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: SomeStructWithEnum.self))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: "\(SomeStructWithEnum.self)")).dereferenced(in: componentsBuilder.componentsObject))
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 1)
    }

    func testBuildSchemaCorrect() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        _ = try componentsBuilder.buildSchema(for: SomeComplexStruct.self)
        _ = try componentsBuilder.buildSchema(for: SomeStructWithEnum.self)

        let ref1 = try componentsBuilder.componentsObject.reference(named: "\(SomeStruct.self)", ofType: JSONSchema.self)
        let ref2 = try componentsBuilder.componentsObject.reference(named: "\(SomeNestedStruct.self)", ofType: JSONSchema.self)
        let ref3 = try componentsBuilder.componentsObject.reference(named: "GenericStruct", ofType: JSONSchema.self)
        let ref4 = try componentsBuilder.componentsObject.reference(named: "\(SomeComplexStruct.self)", ofType: JSONSchema.self)
        let ref5 = try componentsBuilder.componentsObject.reference(named: "\(SomeStructWithEnum.self)", ofType: JSONSchema.self)

        XCTAssertEqual(
            componentsBuilder.componentsObject[ref1],
            .object(properties: [
                "someProp": .integer,
                "id": .string(format: .other("uuid"), required: false)
            ])
        )
        XCTAssertEqual(
            componentsBuilder.componentsObject[ref2],
            .object(
                properties: [
                    "someInt": .integer,
                    "someString": .string(required: false)
                ]
            )
        )
        XCTAssertEqual(
            componentsBuilder.componentsObject[ref3],
            .object(
                properties: [
                    "list": .array(
                        items: .reference(
                            .component(named: "SomeStruct")
                        )
                    ),
                    "listLength": .integer()
                ]
            )
        )
        XCTAssertEqual(
            componentsBuilder.componentsObject[ref4],
            .object(
                properties: [
                    "someNestedStruct2": .reference(
                        .component(named: "SomeNestedStruct")
                    ),
                    "someItems": .reference(
                        .component(named: "GenericStruct")
                    ),
                    "someStruct": .reference(
                        .component(named: "SomeStruct")
                    ),
                    "someNestedStruct": .reference(
                        .component(named: "SomeNestedStruct")
                    )
                ]
            )
        )
        XCTAssertEqual(
            componentsBuilder.componentsObject[ref5],
            .object(
                properties: [
                    "someProp": .integer,
                    "test": .string(allowedValues: Test.allCases.map { .init($0.rawValue) })
                ]
            )
        )
    }
}
