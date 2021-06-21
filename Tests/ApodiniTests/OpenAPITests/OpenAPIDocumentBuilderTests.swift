//
//  Created by Lorena Schlesinger on 09.12.20.
//

import XCTest
@_implementationOnly import OpenAPIKit
@testable import Apodini
@testable import ApodiniOpenAPI
@testable import ApodiniVaporSupport
import ApodiniREST


final class OpenAPIDocumentBuilderTests: ApodiniTests {
    struct SomeStruct: Apodini.Content {
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

        func handle() -> SomeStruct {
            SomeStruct()
        }
    }

    // swiftlint:disable:next function_body_length
    func testAddEndpoint() throws {
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
            
        Group("test") {
            SomeComp()
        }
        .accept(visitor)
        
        visitor.finishParsing()
        
        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<SomeComp>)

        let exporterConfiguration = OpenAPI.ExporterConfiguration()

        var documentBuilder = OpenAPIDocumentBuilder(configuration: exporterConfiguration)
        documentBuilder.addEndpoint(endpoint)
        let document = OpenAPI.Document(
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
                                            .component(named: "\(SomeStruct.self)Response")))
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
                        vendorExtensions: ["x-apodiniHandlerId": AnyCodable(endpoint[AnyHandlerIdentifier.self].rawValue)]
                    )
                )
            ],
            components: .init(
                schemas: [
                    "SomeStruct": .object(properties: ["someProp": .integer]),
                    "SomeStructResponse": .object(
                        title: "\(SomeStruct.self)Response", properties: [
                        ResponseContainer.CodingKeys.data.rawValue: .reference(.component(named: "\(SomeStruct.self)")),
                        ResponseContainer.CodingKeys.links.rawValue: .object(additionalProperties: .init(.string))
                        ])
                ]
            )
        )

        let builtDocument = documentBuilder.build()

        XCTAssertNoThrow(try builtDocument.output(configuration: exporterConfiguration))
        XCTAssertEqual(builtDocument, document)
    }
}
