//
//  Created by Lorena Schlesinger on 09.12.20.
//

import XCTest
import OpenAPIKit
import Vapor
@testable import Apodini

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
        var endpoint = comp.mockEndpoint()
        let endpointTreeNode = EndpointsTreeNode(path: RootPath())
        endpointTreeNode.addEndpoint(&endpoint, at: ["test"])

        let configuration = OpenAPIConfiguration()

        var documentBuilder = OpenAPIDocumentBuilder(configuration: configuration)
        documentBuilder.addEndpoint(endpoint)
        let document = OpenAPI.Document(
            info: configuration.info,
            servers: configuration.servers,
            paths: [
                "test": .init(
                    get: .init(
                        parameters: [
                            Either.parameter(name: "name", context: .query, schema: .string, description: "@Parameter var name: String")
                        ],
                        responses: [
                            .status(code: 200): .init(
                                OpenAPI.Response(
                                    description: "OK",
                                    content: [
                                        .json: .init(schema: .reference(.component(named: "SomeStruct")))
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
                        ]
                    )
                )
            ],
            components: .init(
                schemas: ["SomeStruct": .object(properties: ["someProp": .integer])]
            )
        )

        let builtDocument = documentBuilder.build()
        
        XCTAssertNotNil(documentBuilder.jsonDescription)
        XCTAssertEqual(builtDocument, document)
    }
}
