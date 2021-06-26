//
//  Created by Lorena Schlesinger on 09.12.20.
//

import XCTest
@_implementationOnly import OpenAPIKit
@testable import Apodini
@testable import ApodiniOpenAPI

final class OpenAPIPathsObjectBuilderTests: ApodiniTests {
    struct SomeStruct: Codable {
        var id = 1
        var someProp = "somesome"
    }

    struct ResponseStruct: Apodini.Content {
        var someResponse = "response"
        var someCount: Int?
    }

    @PathParameter var param: String
    
    struct HandlerParam: Handler {
        @Binding
        var pathParam: String

        func handle() -> String {
            "test"
        }
    }

    func testPathBuilder() {
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
        
        var componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &componentsObjectBuilder)
        pathsObjectBuilder.addPathItem(from: endpoint)
        
        XCTAssertEqual(pathsObjectBuilder.pathsObject.count, 1)
        XCTAssertEqual(pathsObjectBuilder.pathsObject.first?.value.get?.tags, ["second"])
    }
    
    func testDefaultTagWithSinglePathParameter() {
        let handler = HandlerParam(pathParam: $param)
        var (endpoint, rendpoint) = handler.mockRelationshipEndpoint(app: app)
        let webService = RelationshipWebServiceModel()
        webService.addEndpoint(&rendpoint, at: [$param, "first"])
        
        var componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &componentsObjectBuilder)
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

        var componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &componentsObjectBuilder)

        
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
            
        Group("test/{pathParam}") {
            SomeComp()
        }
        .accept(visitor)
        
        visitor.finishParsing()
        
        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<SomeComp>)

        pathsObjectBuilder.addPathItem(from: endpoint)
        let path = OpenAPI.Path(stringLiteral: "test/{pathParam}/{id}")
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
            @Parameter var someStruct1: SomeStruct?
            @Parameter var someStruct2: SomeStruct

            func handle() -> String {
                "Hello"
            }
        }

        var componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &componentsObjectBuilder)

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

        let wrappedRef = try componentsObjectBuilder.componentsObject.reference(named: "SomeStruct_SomeStruct", ofType: JSONSchema.self)

        XCTAssertEqual(
            componentsObjectBuilder.componentsObject[wrappedRef],
            .object(
                properties: [
                    "SomeStruct_0": .reference(
                        .component(named: "\(SomeStruct.self)")
                    ),
                    "SomeStruct_1": .reference(
                        .component(named: "\(SomeStruct.self)")
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
            @Parameter var someStructArray: [SomeStruct]

            func handle() -> [SomeStruct] {
                []
            }
        }

        var componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &componentsObjectBuilder)

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
                description: "@Parameter var someStructArray: Array<SomeStruct>",
                content: [
                    .json: .init(schema: .array(items: .reference(.component(named: "\(SomeStruct.self)"))))
                ]
            ),
            responses: [
                .status(code: 200): .init(
                    OpenAPI.Response(
                        description: "OK",
                        content: [
                            .json: .init(schema: .reference(
                                .component(named: "Arrayof\(SomeStruct.self)Response")))
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
            vendorExtensions: ["x-apodiniHandlerId": AnyCodable(endpoint[AnyHandlerIdentifier.self].rawValue)]
        ))

        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains { (key: OpenAPIKit.OpenAPI.Path, value: OpenAPIKit.OpenAPI.PathItem) -> Bool in
            key == path && value == pathItem
        })
        XCTAssertEqual(componentsObjectBuilder.componentsObject.schemas.count, 2)
    }

    func testAddPathItemWithRequestBodyAndResponseStruct() throws {
        struct ComplexComp: Handler {
            @Parameter var someStruct: SomeStruct

            func handle() -> ResponseStruct {
                ResponseStruct()
            }
        }

        var componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &componentsObjectBuilder)

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
                description: "@Parameter var someStruct: SomeStruct",
                content: [
                    .json: .init(schema: .reference(.component(named: "\(SomeStruct.self)")))
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
            vendorExtensions: ["x-apodiniHandlerId": AnyCodable(endpoint[AnyHandlerIdentifier.self].rawValue)]
        ))

        XCTAssertEqual(pathsObjectBuilder.pathsObject.count, 1)
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains(key: path))
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains { (key: OpenAPIKit.OpenAPI.Path, value: OpenAPIKit.OpenAPI.PathItem) -> Bool in
            key == path && value == pathItem
        })
        XCTAssertEqual(componentsObjectBuilder.componentsObject.schemas.count, 3)
    }
}
