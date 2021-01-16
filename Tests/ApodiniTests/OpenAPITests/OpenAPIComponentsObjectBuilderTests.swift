//
//  Created by Lorena Schlesinger on 29.11.20.
//

import XCTest
import Foundation
import NIO
@_implementationOnly import OpenAPIKit
@_implementationOnly import Runtime
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

    struct SomeStruct: Encodable {
        var id: UUID?
        var someProp = 4
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

        struct SomeNestedStruct: Encodable {
            let someInt = 123
            let someString: String?
        }
    }
    
    struct ResponseContainer<T>: Encodable where T: Encodable {
        var data: T
        var links: [String: String]
    }

    func testBuildSchemaNonStructs() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()

        // add primitive type (will not be added to components map, but defined inline)
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
    }
    
    func testBuildSchemaforResponseContainer() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: ResponseContainer<SomeStruct>.self))
        let schema = try componentsBuilder.buildSchema(for: ResponseContainer<SomeStruct>.self)
        
        XCTAssertThrowsError(try JSONSchema.reference(.component(named: "\(ResponseContainer<SomeStruct>.self)")).dereferenced(in: componentsBuilder.componentsObject))
        
        XCTAssertEqual(schema, .object(properties: [
            "data": try componentsBuilder.buildSchema(for: SomeStruct.self),
            "links": try componentsBuilder.buildSchema(for: type(of: someDict))
        ]))
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 1)
    }
    
    func testBuildSchemaComplex_referenceExists() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: SomeComplexStruct.self))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: "\(SomeComplexStruct.self)")).dereferenced(in: componentsBuilder.componentsObject))
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 4)
    }
    
    func testBuildSchemaComplex_arrayReference() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: Array<SomeStruct>.self))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: "\(SomeStruct.self)")).dereferenced(in: componentsBuilder.componentsObject))
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 1)
    }
    
    func testBuildSchemaComplex_optionalReference() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: Optional<SomeStruct>.self))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: "\(SomeStruct.self)")).dereferenced(in: componentsBuilder.componentsObject))
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 1)
    }

    func testBuildSchemaComplex_schemasCorrect() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        _ = try componentsBuilder.buildSchema(for: SomeComplexStruct.self)

        let ref1 = try componentsBuilder.componentsObject.reference(named: "SomeStruct", ofType: JSONSchema.self)
        let ref2 = try componentsBuilder.componentsObject.reference(named: "SomeNestedStruct", ofType: JSONSchema.self)
        let ref3 = try componentsBuilder.componentsObject.reference(named: "GenericStruct", ofType: JSONSchema.self)
        let ref4 = try componentsBuilder.componentsObject.reference(named: "SomeComplexStruct", ofType: JSONSchema.self)

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
    }
}
