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
import ApodiniREST
import ApodiniHTTP


struct SomeTestStruct: Apodini.Content {
    var someProp = 4
}

struct SomeDelegate {
    @Parameter var lazyoptional: String
}

struct SomeRequiredDelegate {
    @Parameter var required: String
    @Parameter var realoptional: String?
}

struct SomeComp: Handler {
    @Parameter var name: String
    
    let someD = Delegate(SomeDelegate())
    let requiredD = Delegate(SomeRequiredDelegate(), .required)

    func handle() -> SomeTestStruct {
        SomeTestStruct()
    }
}

final class OpenAPIDocumentBuilderTests: ApodiniTests {
    func testAddHTTPEndpoint() throws {
        try runEndpointTest(
            httpConfiguration: HTTPExporterConfiguration(),
            responseSchema:
                .reference(.component(named: "\(SomeTestStruct.self)"))
                .with(title: "\(SomeTestStruct.self)Response"),
            app: app)
    }
    
    func testAddRESTEndpoint() throws {
        try runEndpointTest(
            httpConfiguration: HTTPExporterConfiguration(useResponseContainer: true),
            responseSchema: .object(
                title: "\(SomeTestStruct.self)Response",
                properties: [
                    ResponseContainer.CodingKeys.data.rawValue: .reference(.component(named: "\(SomeTestStruct.self)")),
                    ResponseContainer.CodingKeys.links.rawValue: .object(additionalProperties: .init(.string))
            ]),
            app: app)
    }
}

private func runEndpointTest(httpConfiguration: HTTPExporterConfiguration, responseSchema: JSONSchema, app: Application) throws {
    let modelBuilder = SemanticModelBuilder(app)
    let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        
    Group("test") {
        SomeComp()
    }
    .accept(visitor)
    
    visitor.finishParsing()
    
    let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<SomeComp>)
    let exporterConfiguration = OpenAPI.ExporterConfiguration(parentConfiguration: httpConfiguration)

    var documentBuilder = OpenAPIDocumentBuilder(configuration: exporterConfiguration, rootPath: nil)
    documentBuilder.addEndpoint(endpoint)
    let document = manuallyCreateDocument(responseSchema, endpoint, exporterConfiguration)

    let builtDocument = documentBuilder.build()

    XCTAssertNoThrow(try builtDocument.output(configuration: exporterConfiguration))
    XCTAssertEqual(builtDocument, document)
}

// swiftlint:disable:next function_body_length
private func manuallyCreateDocument(_ responseSchema: JSONSchema, _ endpoint: AnyEndpoint, _ exporterConfiguration: ApodiniOpenAPI.OpenAPI.ExporterConfiguration) -> OpenAPIKit.OpenAPI.Document {
    OpenAPI.Document(
        info: OpenAPI.Document.Info(title: exporterConfiguration.title ?? "", version: exporterConfiguration.version ?? ""),
        servers: exporterConfiguration.serverUrls.map {
            .init(url: $0)
        },
        paths: [
            "test": .init(
                get: .init(
                    // As there is no custom tag in this case, `tags` is derived by rules (i.e., last appended string path compontent).
                    tags: ["test"],
                    // As there is no custom description in this case, `description` and `operationId` are the same.
                    description: endpoint.description,
                    operationId: endpoint[AnyHandlerIdentifier.self].rawValue,
                    parameters: [
                        Either.parameter(name: "name",
                                         context: .query(required: true),
                                         schema: .string,
                                         description: "@Parameter var name: String"),
                        Either.parameter(name: "lazyoptional",
                                         context: .query(required: false),
                                         schema: .string,
                                         description: "@Parameter var lazyoptional: String"),
                        Either.parameter(name: "required",
                                         context: .query(required: true),
                                         schema: .string,
                                         description: "@Parameter var required: String"),
                        Either.parameter(name: "realoptional",
                                         context: .query(required: false),
                                         schema: .string,
                                         description: "@Parameter var realoptional: String?")
                    ],
                    responses: [
                        .status(code: 200): .init(
                            OpenAPI.Response(
                                description: "OK",
                                content: [
                                    .json: .init(schema: .reference(
                                        .component(named: "\(SomeTestStruct.self)Response")))
                                ]
                            )
                        ),
                        .status(code: 401): .init(
                            OpenAPI.Response(description: "Unauthorized")
                        ),
                        .status(code: 403): .init(
                            OpenAPI.Response(description: "Forbidden")
                        ),
                        .status(code: 404): .init(
                            OpenAPI.Response(description: "Not Found")
                        ),
                        .status(code: 500): .init(
                            OpenAPI.Response(description: "Internal Server Error")
                        )
                    ],
                    vendorExtensions: [
                        "x-apodiniHandlerId": AnyCodable(endpoint[AnyHandlerIdentifier.self].rawValue),
                        "x-apodiniHandlerCommunicationPattern": AnyCodable(endpoint[CommunicationPattern.self].rawValue)
                    ]
                )
            )
        ],
        components: .init(
            schemas: [
                "SomeTestStruct": .object(properties: ["someProp": .integer]),
                "SomeTestStructResponse": responseSchema
            ]
        )
    )
}
