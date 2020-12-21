//
//  Created by Lorena Schlesinger on 09.12.20.
//

import XCTest
import OpenAPIKit
import Vapor
@testable import Apodini

final class OpenAPIDocumentBuilderTests: XCTestCase {

    struct SomeStruct: Vapor.Content {
        var someProp = 4
    }

    struct SomeComp: Component {
        @Parameter
        var name: String

        func handle() -> SomeStruct {
            SomeStruct()
        }
    }

    func testAddEndpoint() {
        let comp = SomeComp()
        let parameterBuilder = ParameterBuilder(from: comp)
        parameterBuilder.build()
        var endpoint = Endpoint(
                description: String(describing: comp),
                context: Context(contextNode: ContextNode()),
                operation: Operation.update,
                requestHandler: SharedSemanticModelBuilder.createRequestHandler(with: comp),
                handleReturnType: SomeComp.Response.self,
                responseType: SomeComp.Response.self,
                parameters: parameterBuilder.parameters
        )
        let endpointTreeNode = EndpointsTreeNode(path: RootPath())
        endpointTreeNode.addEndpoint(&endpoint, at: ["test"])

        let configuration = OpenAPIConfiguration()

        var documentBuilder = OpenAPIDocumentBuilder(configuration: configuration)
        documentBuilder.addEndpoint(endpoint)
        let document = OpenAPI.Document(
                info: configuration.info,
                servers: configuration.servers,
                paths: ["test": .init(
                        put: .init(
                                parameters: [
                                    Either.parameter(name: "_name", context: .query, schema: .string)
                                ],
                                responses: [.status(code: 200): .init(
                                        OpenAPI.Response(description: "", content: [
                                            .json: .init(schema: .reference(
                                                    .component(named: "SomeStruct")
                                            ))
                                        ]))
                                ]
                        )
                )],
                components: .init(schemas: ["SomeStruct": .object(
                        properties: ["someProp": .integer]
                )])
        )

        XCTAssertEqual(documentBuilder.build(), document)
    }

}
