//
//  Created by Lorena Schlesinger on 09.12.20.
//

import XCTest
@_implementationOnly import OpenAPIKit
@testable import Apodini
@testable import ApodiniOpenAPI
@testable import ApodiniVaporSupport

final class OpenAPIDocumentBuilderTests: XCTestCase {
    struct SomeStruct: Apodini.Content {
        var someProp = 4
    }

    struct SomeComp: Handler {
        @Parameter var name: String

        func handle() -> SomeStruct {
            SomeStruct()
        }
    }

    func testAddEndpoint() {
        let comp = SomeComp()
        let webService = WebServiceModel()
        var endpoint = comp.mockEndpoint()
        webService.addEndpoint(&endpoint, at: ["test"])

        let configuration = OpenAPIConfiguration()

        var documentBuilder = OpenAPIDocumentBuilder(configuration: configuration)
        documentBuilder.addEndpoint(endpoint)
        let document = OpenAPI.Document(
            info: OpenAPI.Document.Info(title: configuration.title ?? "", version: configuration.version ?? ""),
            servers: configuration.serverUrls.map {
                .init(url: $0)
            },
            paths: [
                "test": .init(
                    get: .init(
                        // As there is no custom tag in this case, `tags` is derived by rules (i.e., last appended string path compontent).
                        tags: ["test"],
                        // As there is no custom description in this case, `description` and `operationId` are the same.
                        description: endpoint.description,
                        operationId: endpoint.identifier.rawValue,
                        parameters: [
                            Either.parameter(name: "name", context: .query, schema: .string, description: "@Parameter var name: String")
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
                        vendorExtensions: ["x-apodiniHandlerId": AnyCodable(endpoint.identifier.rawValue)]
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

        XCTAssertNoThrow(try builtDocument.output(.json))
        XCTAssertEqual(builtDocument, document)
    }
}
