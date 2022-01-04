//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import OpenAPIKit
@testable import Apodini
@testable import ApodiniOpenAPI
import ApodiniTypeInformation
import ApodiniREST


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

final class OpenAPIComponentsObjectBuilderTests: XCTestCase {
    let someString = "Some String"
    let someInt = 42
    let someDouble = 42.0
    let someBool = true
    let someDict = ["someKey": "someValue"]
    let someArray = [1, 2, 3]
    let someEither: Either<Int, String> = .init("someString")
    let someOptional: String? = nil
    let someOptionalUUID: UUID? = nil
    let someEnum = Test.system

    /// Create schema for primitive types and non structs (will not be added to components map, but defined inline).
    func testBuildSchemaNonStructs() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: type(of: someString)))
        var schema = try componentsBuilder.buildSchema(for: type(of: someString))
        XCTAssertEqual(schema, .string())
        
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: type(of: someDict)))
        schema = try componentsBuilder.buildSchema(for: type(of: someDict))
        XCTAssertEqual(schema, .object(additionalProperties: .init(.string())))
        
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 0)
        XCTAssertEqual(componentsBuilder.componentsObject, .noComponents)
        
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: type(of: someEnum)))
        schema = try componentsBuilder.buildSchema(for: type(of: someEnum))
        XCTAssertEqual(schema, .string(allowedValues: Test.allCases.map {
                .init($0.rawValue)
        }))
        
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 0)
        XCTAssertEqual(componentsBuilder.componentsObject, .noComponents)
        
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: type(of: someArray)))
        schema = try componentsBuilder.buildSchema(for: type(of: someArray))
        XCTAssertEqual(schema, .array(items: .init(.integer())))
    }
    
    /// Create response schema and add it to components, handle type and array of type differently.
    func testBuildSchemaForResponsesWithArrayAndDict() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        
        let responseSchemaNameStruct = "\(SomeStruct.self)Response"
        XCTAssertNoThrow(try componentsBuilder.buildResponse(for: SomeStruct.self))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: responseSchemaNameStruct)).dereferenced(in: componentsBuilder.componentsObject))
        
        let responseSchemaNameDict = "Dictionaryof\(SomeStruct.self)Response"
        XCTAssertNoThrow(try componentsBuilder.buildResponse(for: Dictionary<String, SomeStruct>.self))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: responseSchemaNameDict)).dereferenced(in: componentsBuilder.componentsObject))
        
        let responseSchemaNameArray = "Arrayof\(SomeStruct.self)Response"
        XCTAssertNoThrow(try componentsBuilder.buildResponse(for: Array<SomeStruct>.self))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: responseSchemaNameArray)).dereferenced(in: componentsBuilder.componentsObject))
        
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 4)
    }
    
    /// Create response schema and add it to components.
    func testBuildSchemaForResponses() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        XCTAssertNoThrow(try componentsBuilder.buildResponse(for: SomeStruct.self))
        let responseSchemaName = "\(SomeStruct.self)Response"
        let ref = try componentsBuilder.componentsObject.reference(named: responseSchemaName, ofType: JSONSchema.self)
        
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: responseSchemaName)).dereferenced(in: componentsBuilder.componentsObject))
        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 2)
        XCTAssertEqual(
            componentsBuilder.componentsObject[ref],
            .object(
                title: responseSchemaName,
                properties: [
                    ResponseContainer.CodingKeys.data.rawValue: try componentsBuilder.buildSchema(for: SomeStruct.self),
                    ResponseContainer.CodingKeys.links.rawValue: try componentsBuilder.buildSchema(for: ResponseContainer.Links.self)
                ]
            )
        )
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
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: SomeComplexStruct.self))
        XCTAssertNoThrow(try componentsBuilder.buildSchema(for: SomeStructWithEnum.self))
        
        let ref1 = try componentsBuilder.componentsObject.reference(named: "\(SomeStruct.self)", ofType: JSONSchema.self)
        let ref2 = try componentsBuilder.componentsObject.reference(named: "\(SomeNestedStruct.self)", ofType: JSONSchema.self)
        let ref3 = try componentsBuilder.componentsObject.reference(named: "GenericStruct\(OpenAPISchemaConstants.genericsPrefix)SomeStruct", ofType: JSONSchema.self)
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
                        .component(named: "GenericStruct\(OpenAPISchemaConstants.genericsPrefix)SomeStruct")
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
    
    func testTypeInformation() throws {
        enum Number: UInt8 {
            case zero
            case one
            case two
            case three
        }
        
        struct Card {
            let number: Number
        }
        
        enum Badge: String {
            case newbie
            case explorer
            case achiever
            case worldSaver
        }
        
        struct Player {
            let hand: [Card]
            let teamMates: [String: String]
            let website: URL
            let joinedAt: Date
            let budget: UInt64
            let badge: Badge
        }
        
        struct Game {
            let players: [String: Player]
            let newPlayers: [Player]
        }
        
        struct Casino {
            let tables: [Game]
        }
        
        let casino = try TypeInformation(type: Casino.self)
        let game = try TypeInformation(type: Game.self)
        let player = try TypeInformation(type: Player.self)
        let badge = try TypeInformation(type: Badge.self)
        let card = try TypeInformation(type: Card.self)
        let number = try TypeInformation(type: Number.self)
        
        let objectTypes = casino.objectTypes()
        let enums = casino.enums()
        
        XCTAssertEqual(objectTypes.count, 4)
        XCTAssertEqual(casino.typeName.mangledName, "Casino")
        XCTAssertEqual(casino.typeName.definedIn, "ApodiniTests")
        XCTAssertEqual(casino.property("tables")?.type, .repeated(element: game))
        
        let unwrappedBadge = try XCTUnwrap(enums.first { $0.typeName.mangledName == "Badge" })
        XCTAssertEqual(unwrappedBadge.rawValueType, .scalar(.string))
        XCTAssertEqual(unwrappedBadge, badge)
        
        let unwrappedNumber = try XCTUnwrap(enums.first { $0.typeName.mangledName == "Number" })
        XCTAssertEqual(unwrappedNumber.rawValueType, .scalar(.uint8))
        XCTAssertEqual(unwrappedNumber, number)
        
        XCTAssertEqual(player.objectProperties.count, 6)
        XCTAssertEqual(player.property("badge")?.type, badge)
        XCTAssertEqual(player.property("hand")?.type, .repeated(element: try TypeInformation(type: Card.self)))
        
        XCTAssert(game.isContained(in: casino))
        XCTAssert(player.isContained(in: casino))
        XCTAssert(player.isContained(in: game))
        XCTAssert(number.isContained(in: card))
        XCTAssert(!badge.contains(card))
        
        [game, player, badge, card, number].forEach {
            XCTAssert(casino.contains($0))
        }
    }
    
    func testJSONSchemaFromPrimitiveTypes() throws {
        let void: Void = ()
        XCTAssertEqual(JSONSchema.string, .from(type(of: void)))
        XCTAssertEqual(JSONSchema.boolean, .from(Bool.self))
        XCTAssertEqual(JSONSchema.integer, .from(Int.self))
        XCTAssertEqual(JSONSchema.integer(format: .int32), .from(Int32.self))
        XCTAssertEqual(JSONSchema.integer(format: .int64), .from(Int64.self))
        XCTAssertEqual(JSONSchema.integer(format: .other("int8")), .from(Int8.self))
        XCTAssertEqual(JSONSchema.integer(format: .other("int16")), .from(Int16.self))
        XCTAssertEqual(JSONSchema.integer(format: .other("uint")), .from(UInt.self))
        XCTAssertEqual(JSONSchema.integer(format: .other("uint8")), .from(UInt8.self))
        XCTAssertEqual(JSONSchema.integer(format: .other("uint16")), .from(UInt16.self))
        XCTAssertEqual(JSONSchema.integer(format: .other("uint32")), .from(UInt32.self))
        XCTAssertEqual(JSONSchema.integer(format: .other("uint64")), .from(UInt64.self))
        XCTAssertEqual(JSONSchema.string, .from(String.self))
        XCTAssertEqual(JSONSchema.number(format: .double), .from(Double.self))
        XCTAssertEqual(JSONSchema.number(format: .float), .from(Float.self))
        XCTAssertEqual(JSONSchema.string(format: .other("uuid")), .from(UUID.self))
        XCTAssertEqual(JSONSchema.string(format: .other("url")), .from(URL.self))
        XCTAssertEqual(JSONSchema.string(format: .date), .from(Date.self))
        XCTAssertEqual(JSONSchema.string(format: .binary), .from(Data.self))
        XCTAssertEqual(JSONSchema.array(items: .string), .from([String].self))
        
        let nullSchema = JSONSchema.from(primitiveType: .null)
        let nullData = try XCTUnwrap(try? nullSchema.defaultValue?.encodeToJSON())
        XCTAssertNoThrow(try JSONDecoder().decode(Null.self, from: nullData))
    }
}
