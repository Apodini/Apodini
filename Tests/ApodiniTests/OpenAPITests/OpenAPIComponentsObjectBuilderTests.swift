//
//  Created by Lorena Schlesinger on 29.11.20.
//

import XCTest
import ApodiniTypeReflection
@_implementationOnly import OpenAPIKit
@testable import Apodini
@testable import ApodiniVaporSupport
@testable import ApodiniOpenAPI
import ApodiniREST


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

    /// Create schema for primitive types and non structs (will not be added to components map, but defined inline).
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
        XCTAssertEqual(schema, .string(allowedValues: Test.allCases.map {
            .init($0.rawValue)
        }))

        XCTAssertEqual(componentsBuilder.componentsObject.schemas.count, 0)
        XCTAssertEqual(componentsBuilder.componentsObject, .noComponents)
    }

    /// Create response schema and add it to components, handle type and array of type differently.
    func testBuildSchemaForResponsesWithArrayAndDict() throws {
        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        let responseSchemaName1 = "\(SomeStruct.self)Response"
        let responseSchemaName2 = "Arrayof\(SomeStruct.self)Response"
        let responseSchemaName3 = "Dictionaryof\(SomeStruct.self)Response"

        XCTAssertNoThrow(try componentsBuilder.buildResponse(for: SomeStruct.self))
        XCTAssertNoThrow(try componentsBuilder.buildResponse(for: Array<SomeStruct>.self))
        XCTAssertNoThrow(try componentsBuilder.buildResponse(for: Dictionary<String, SomeStruct>.self))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: responseSchemaName1)).dereferenced(in: componentsBuilder.componentsObject))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: responseSchemaName2)).dereferenced(in: componentsBuilder.componentsObject))
        XCTAssertNoThrow(try JSONSchema.reference(.component(named: responseSchemaName3)).dereferenced(in: componentsBuilder.componentsObject))
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
        let ref3 = try componentsBuilder.componentsObject.reference(named: "GenericStruct\(OpenAPISchemaConstants.replaceOpenAngleBracket)SomeStruct\(OpenAPISchemaConstants.replaceCloseAngleBracket)", ofType: JSONSchema.self)
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
                        .component(named: "GenericStruct\(OpenAPISchemaConstants.replaceOpenAngleBracket)SomeStruct\(OpenAPISchemaConstants.replaceCloseAngleBracket)")
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
                    "test": .string(allowedValues: Test.allCases.map {
                        .init($0.rawValue)
                    })
                ]
            )
        )
    }

    func testCreateReflectionInfoTree() throws {
        struct Card {
            let number: Int
        }

        struct Player {
            let hand: [Card]
            let teamMates: [String: String]
        }

        struct Game {
            let players: [String: Player]
            let newPlayers: [Player]
        }

        struct Casino {
            let tables: [Game]
        }

        let tree = try OpenAPIComponentsObjectBuilder.node(Casino.self)

        XCTAssertEqual(tree.children.count, 1)

        let tablesNode = tree.children.first {
            $0.value.propertyInfo?.name == "tables"
        }

        XCTAssertEqual(tablesNode?.children.count, 2)
        XCTAssertTrue(tablesNode?.value.cardinality == .zeroToMany(.array))

        // check for correct children of tablesNode
        let stringNode = try ReflectionInfo.node(String.self)
        let playerNode = try ReflectionInfo.node(Player.self)
        let newPlayersNode = tablesNode?.children.first {
            $0.value.propertyInfo?.name == "newPlayers"
        }
        let playersNode = tablesNode?.children.first {
            $0.value.propertyInfo?.name == "players"
        }

        XCTAssertEqual(playersNode?.children.count, 2)
        XCTAssertTrue(playersNode?.value.cardinality == .zeroToMany(.dictionary(key: stringNode.value, value: playerNode.value)))
        XCTAssertEqual(newPlayersNode?.children.count, 2)
        XCTAssertTrue(newPlayersNode?.value.cardinality == .zeroToMany(.array))

        let playersHandNode = playersNode?.children.first {
            $0.value.propertyInfo?.name == "hand"
        }
        let newPlayersHandNode = newPlayersNode?.children.first {
            $0.value.propertyInfo?.name == "hand"
        }

        XCTAssertEqual(playersHandNode?.value, newPlayersHandNode?.value)

        let playersTeamMatesNode = playersNode?.children.first {
            $0.value.propertyInfo?.name == "teamMates"
        }
        let newPlayersTeamMatesNode = newPlayersNode?.children.first {
            $0.value.propertyInfo?.name == "teamMates"
        }

        XCTAssertEqual(playersTeamMatesNode?.value, newPlayersTeamMatesNode?.value)
    }
}
