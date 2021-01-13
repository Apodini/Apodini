//
//  Created by Lorena Schlesinger on 09.12.20.
//

import XCTest
import OpenAPIKit
@testable import Apodini

final class OpenAPIPathsObjectBuilderTests: XCTestCase {
    struct SomeComp: Handler {
        @Parameter(.http(.query)) var name: String

        @Parameter(.http(.path)) var id: String

        func handle() -> String {
            "Hello \(name)!"
        }
    }

    struct SomeStruct: Codable {
        var id = 1
        var someProp = "somesome"
    }

    struct ResponseStruct: Apodini.Content {
        var someResponse = "response"
        var someCount: Int?
    }

    struct ComplexComp: Handler {
        @Parameter var someStruct: SomeStruct

        func handle() -> ResponseStruct {
            ResponseStruct()
        }
    }

    struct WrappingParamsComp: Handler {
        @Parameter var someStruct1: SomeStruct
        @Parameter var someStruct2: SomeStruct

        func handle() -> String {
            "Hello"
        }
    }

    func testPathBuilder() {
        let pathUUID = UUID()
        let parameter = Parameter<String>(from: pathUUID)
        let pathComponents: [_PathComponent] = ["test", parameter]
        let endpointParameter1 = EndpointParameter<String>(
            id: parameter.id,
            name: "pathParam",
            label: "pathParam",
            nilIsValidValue: true,
            necessity: .required,
            defaultClosurePresent: false,
            options: parameter.options
        )
        let endpointParameter2 = EndpointParameter<String>(
            id: UUID(),
            name: "queryParam",
            label: "queryParam",
            nilIsValidValue: false,
            necessity: .optional,
            defaultClosurePresent: false,
            options: PropertyOptionSet([.http(.query)])
        )
        var builder = OpenAPIPathBuilder(pathComponents, parameters: [endpointParameter1, endpointParameter2])

        XCTAssertEqual(builder.path, OpenAPI.Path(stringLiteral: "test/{pathParam}"))
    }

    func testAddPathItemOperationParams() {
        var componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        let comp = SomeComp()
        var endpoint = comp.mockEndpoint()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &componentsObjectBuilder)
        let endpointTreeNode = EndpointsTreeNode(path: RootPath())
        endpointTreeNode.addEndpoint(&endpoint, at: ["test/{pathParam}"])
        pathsObjectBuilder.addPathItem(from: endpoint)
        let path = OpenAPI.Path(stringLiteral: "test/{pathParam}")
        let queryParam = Either.parameter(name: "name", context: .query, schema: .string, description: "@Parameter var name: String")
        let pathParam = Either.parameter(name: "id", context: .path, schema: .string, description: "@Parameter var id: String")

        XCTAssertEqual(pathsObjectBuilder.pathsObject.count, 1)
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains(key: path))
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains { (key: OpenAPI.Path, value: OpenAPI.PathItem) -> Bool in
            key == path && ((value.get?.parameters.contains(queryParam)) != nil) && ((value.get?.parameters.contains(pathParam)) != nil)
        })
    }

    func testAddPathItemOperationWrappedParams() throws {
        var componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        let comp = WrappingParamsComp()
        var endpoint = comp.mockEndpoint()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &componentsObjectBuilder)
        let endpointTreeNode = EndpointsTreeNode(path: RootPath())
        endpointTreeNode.addEndpoint(&endpoint, at: ["test"])
        pathsObjectBuilder.addPathItem(from: endpoint)
        let path = OpenAPI.Path(stringLiteral: "test")

        let wrappedRef = try componentsObjectBuilder.componentsObject.reference(named: "SomeStruct_SomeStruct", ofType: JSONSchema.self)

        XCTAssertEqual(
            componentsObjectBuilder.componentsObject[wrappedRef],
            .object(
                properties: [
                    "SomeStruct_0": .reference(
                        .component(named: "SomeStruct")
                    ),
                    "SomeStruct_1": .reference(
                        .component(named: "SomeStruct")
                    )
                ]
            )
        )

        XCTAssertEqual(pathsObjectBuilder.pathsObject.count, 1)
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains(key: path))
        XCTAssertEqual(componentsObjectBuilder.componentsObject.schemas.count, 2)
    }

    func testAddPathItemWithRequestBodyAndResponseStruct() {
        var componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &componentsObjectBuilder)
        let endpointTreeNode = EndpointsTreeNode(path: RootPath())
        let comp = ComplexComp()
        var endpoint = comp.mockEndpoint()
        endpointTreeNode.addEndpoint(&endpoint, at: ["test"])
        pathsObjectBuilder.addPathItem(from: endpoint)
        let path = OpenAPI.Path(stringLiteral: "/test")
        let pathItem = OpenAPI.PathItem(get: OpenAPI.Operation(
            parameters: [],
            requestBody: OpenAPI.Request(
                description: "@Parameter var someStruct: SomeStruct",
                content: [
                    .json: .init(schema: .reference(.component(named: "SomeStruct")))
                ]
            ),
            responses: [
                .status(code: 200): .init(
                    OpenAPI.Response(description: "OK", content: [
                        .json: .init(schema: .reference(.component(named: "ResponseStruct")))
                    ])),
                .status(code: 401): .init(
                    OpenAPI.Response(description: "Unauthorized")),
                .status(code: 403): .init(
                    OpenAPI.Response(description: "Forbidden")),
                .status(code: 404): .init(
                    OpenAPI.Response(description: "Not Found")),
                .status(code: 500): .init(
                    OpenAPI.Response(description: "Internal Server Error"))
            ],
            security: nil))

        XCTAssertEqual(pathsObjectBuilder.pathsObject.count, 1)
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains(key: path))
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains { (key: OpenAPI.Path, value: OpenAPI.PathItem) -> Bool in
            key == path && value == pathItem
        })
        XCTAssertEqual(componentsObjectBuilder.componentsObject.schemas.count, 2)
    }
}
