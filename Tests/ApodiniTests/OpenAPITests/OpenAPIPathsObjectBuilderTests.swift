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


struct TestStruct: Codable {
    var id = 1
    var someProp = "somesome"
}

struct ResponseStruct: Apodini.Content {
    var someResponse = "response"
    var someCount: Int?
}

final class OpenAPIPathsObjectBuilderTests: ApodiniTests {
    @PathParameter var param: String
    
    struct HandlerParam: Handler {
        @Binding
        var pathParam: String

        func handle() -> String {
            "test"
        }

        var metadata: Metadata {
            Summary("This handler returns the string 'test'.")
        }
    }

    func testPathBuilder() throws {
        let handler = HandlerParam(pathParam: $param)
        let endpoint = handler.mockEndpoint(app: app)
        var pathParameter = EndpointPathParameter<String>(id: _param.id)
        pathParameter.scoped(on: endpoint)
        
        let path: [EndpointPath] = [.string("test"), .parameter(pathParameter)]
        let pathString = path.build(with: OpenAPIPathBuilder.self)
        
        XCTAssertEqual(pathString, OpenAPI.Path(stringLiteral: "test/{pathParam}"))
    }
    
    func testDefaultTagWithPathParameter() throws {
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        
        Group("first", "second", $param, "third") {
            HandlerParam(pathParam: $param)
        }
        .accept(visitor)
        
        visitor.finishParsing()
        
        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<HandlerParam>)
        
        let componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: componentsObjectBuilder, versionAsRootPrefix: Version())
        pathsObjectBuilder.addPathItem(from: endpoint)
        
        XCTAssertEqual(pathsObjectBuilder.pathsObject.count, 1)
        XCTAssertEqual(pathsObjectBuilder.pathsObject.first?.value.get?.tags, ["second"])

        XCTAssertEqual(pathsObjectBuilder.pathsObject.first?.value.get?.summary, "This handler returns the string 'test'.")
    }
    
    func testDefaultTagWithSinglePathParameter() throws {
        let handler = HandlerParam(pathParam: $param)
        var (endpoint, rendpoint) = handler.mockRelationshipEndpoint(app: app)
        let webService = RelationshipWebServiceModel()
        webService.addEndpoint(&rendpoint, at: [$param, "first"])
        
        let componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: componentsObjectBuilder, versionAsRootPrefix: nil)
        pathsObjectBuilder.addPathItem(from: endpoint)
        
        XCTAssertEqual(pathsObjectBuilder.pathsObject.count, 1)
        XCTAssertEqual(pathsObjectBuilder.pathsObject.first?.value.get?.tags, ["default"])
    }
    
    func testAddPathItemOperationParams() throws {
        struct SomeComp: Handler {
            @Parameter(.http(.query)) var name: String
            
            @Parameter(.http(.path)) var id: String
            
            func handle() -> String {
                "Hello \(name)!"
            }
        }
        
        let componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: componentsObjectBuilder, versionAsRootPrefix: Version())
        
        
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        
        Group("test/{pathParam}") {
            SomeComp()
        }
        .accept(visitor)
        
        visitor.finishParsing()
        
        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<SomeComp>)
        
        pathsObjectBuilder.addPathItem(from: endpoint)
        let path = OpenAPI.Path(stringLiteral: "/v1/test/{pathParam}/{id}")
        let queryParam = Either.parameter(name: "name", context: .query, schema: .string, description: "@Parameter var name: String")
        let pathParam = Either.parameter(name: "id", context: .path, schema: .string, description: "@Parameter var id: String")
        
        XCTAssertEqual(pathsObjectBuilder.pathsObject.count, 1)
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains(key: path))
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains { (key: OpenAPIKit.OpenAPI.Path, value: OpenAPIKit.OpenAPI.PathItem) -> Bool in
            key == path && ((value.get?.parameters.contains(queryParam)) != nil) && ((value.get?.parameters.contains(pathParam)) != nil)
        })
    }
    
    func testAddPathItemOperationWrappedParams() throws {
        struct WrappingParamsComp: Handler {
            @Parameter var someStruct1: TestStruct?
            @Parameter var someStruct2: TestStruct
            
            func handle() -> String {
                "Hello"
            }
        }
        
        let componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: componentsObjectBuilder, versionAsRootPrefix: nil)
        
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        
        Group("test") {
            WrappingParamsComp()
        }
        .accept(visitor)
        
        visitor.finishParsing()
        
        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<WrappingParamsComp>)
        
        pathsObjectBuilder.addPathItem(from: endpoint)
        let path = OpenAPI.Path(stringLiteral: "test")
        
        let wrappedRef = try componentsObjectBuilder.componentsObject.reference(named: "TestStruct_TestStruct", ofType: JSONSchema.self)
        
        XCTAssertEqual(
            componentsObjectBuilder.componentsObject[wrappedRef],
            .object(
                properties: [
                    "TestStruct_0": .reference(
                        .component(named: "\(TestStruct.self)")
                    ),
                    "TestStruct_1": .reference(
                        .component(named: "\(TestStruct.self)")
                    )
                ]
            )
        )
        
        XCTAssertEqual(pathsObjectBuilder.pathsObject.count, 1)
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains(key: path))
        XCTAssertEqual(componentsObjectBuilder.componentsObject.schemas.count, 3)
    }
    
    func testAddPathItemOperationArrayParams() throws {
        struct ArrayParamsComp: Handler {
            @Parameter var someStructArray: [TestStruct]
            
            func handle() -> [TestStruct] {
                []
            }
        }
        
        let componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: componentsObjectBuilder, versionAsRootPrefix: nil)
        
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        
        Group("test") {
            ArrayParamsComp()
        }
        .accept(visitor)
        
        visitor.finishParsing()
        
        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<ArrayParamsComp>)
        
        pathsObjectBuilder.addPathItem(from: endpoint)
        let path = OpenAPI.Path(stringLiteral: "test")
        
        let pathItem = OpenAPI.PathItem(get: OpenAPI.Operation(
            // As there is no custom tag in this case, `tags` is derived by rules (i.e., last appended string path compontent).
            tags: ["test"],
            // As there is no custom description in this case, `description` and `operationId` are the same.
            description: endpoint.description,
            operationId: endpoint[AnyHandlerIdentifier.self].rawValue,
            parameters: [],
            requestBody: OpenAPI.Request(
                description: "@Parameter var someStructArray: Array<TestStruct>",
                content: [
                    .json: .init(schema: .array(items: .reference(.component(named: "\(TestStruct.self)"))))
                ]
            ),
            responses: [
                .status(code: 200): .init(
                    OpenAPI.Response(
                        description: "OK",
                        content: [
                            .json: .init(schema: .reference(
                                .component(named: "Arrayof\(TestStruct.self)Response")))
                        ]
                    )),
                .status(code: 401): .init(
                    OpenAPI.Response(description: "Unauthorized")),
                .status(code: 403): .init(
                    OpenAPI.Response(description: "Forbidden")),
                .status(code: 404): .init(
                    OpenAPI.Response(description: "Not Found")),
                .status(code: 500): .init(
                    OpenAPI.Response(description: "Internal Server Error"))
            ],
            vendorExtensions: [
                "x-apodiniHandlerId": AnyCodable(endpoint[AnyHandlerIdentifier.self].rawValue),
                "x-apodiniHandlerCommunicationalPattern": AnyCodable(endpoint[CommunicationalPattern.self].rawValue)
            ]
        ))
        
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains { (key: OpenAPIKit.OpenAPI.Path, value: OpenAPIKit.OpenAPI.PathItem) -> Bool in
            key == path && value == pathItem
        })
        XCTAssertEqual(componentsObjectBuilder.componentsObject.schemas.count, 2)
    }
    
    func testAddPathItemWithRequestBodyAndResponseStruct() throws {
        struct ComplexComp: Handler {
            @Parameter var someStruct: TestStruct
            
            func handle() -> ResponseStruct {
                ResponseStruct()
            }
        }
        
        let componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: componentsObjectBuilder, versionAsRootPrefix: nil)
        
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        
        Group("test") {
            ComplexComp()
        }
        .accept(visitor)
        
        visitor.finishParsing()
        
        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<ComplexComp>)
        
        pathsObjectBuilder.addPathItem(from: endpoint)
        
        let path = OpenAPI.Path(stringLiteral: "/test")
        let pathItem = OpenAPI.PathItem(get: OpenAPI.Operation(
            // As there is no custom tag in this case, `tags` is derived by rules (i.e., last appended string path compontent).
            tags: ["test"],
            // As there is no custom description in this case, `description` and `operationId` are the same.
            description: endpoint.description,
            operationId: endpoint[AnyHandlerIdentifier.self].rawValue,
            parameters: [],
            requestBody: OpenAPI.Request(
                description: "@Parameter var someStruct: TestStruct",
                content: [
                    .json: .init(schema: .reference(.component(named: "\(TestStruct.self)")))
                ]
            ),
            responses: [
                .status(code: 200): .init(
                    OpenAPI.Response(
                        description: "OK",
                        content: [
                            .json: .init(schema: .reference(
                                .component(named: "\(ResponseStruct.self)Response")))
                        ]
                    )),
                .status(code: 401): .init(
                    OpenAPI.Response(description: "Unauthorized")),
                .status(code: 403): .init(
                    OpenAPI.Response(description: "Forbidden")),
                .status(code: 404): .init(
                    OpenAPI.Response(description: "Not Found")),
                .status(code: 500): .init(
                    OpenAPI.Response(description: "Internal Server Error"))
            ],
            vendorExtensions: [
                "x-apodiniHandlerId": AnyCodable(endpoint[AnyHandlerIdentifier.self].rawValue),
                "x-apodiniHandlerCommunicationalPattern": AnyCodable(endpoint[CommunicationalPattern.self].rawValue)
            ]
        ))
        
        XCTAssertEqual(pathsObjectBuilder.pathsObject.count, 1)
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains(key: path))
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains { (key: OpenAPIKit.OpenAPI.Path, value: OpenAPIKit.OpenAPI.PathItem) -> Bool in
            key == path && value == pathItem
        })
        XCTAssertEqual(componentsObjectBuilder.componentsObject.schemas.count, 3)
    }
}
