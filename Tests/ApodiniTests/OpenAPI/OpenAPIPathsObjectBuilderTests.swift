//
//  Created by Lorena Schlesinger on 09.12.20.
//

import XCTest
import OpenAPIKit
@testable import Apodini

final class OpenAPIPathsObjectBuilderTests: XCTestCase {

    struct SomeComp: Component {
        func handle() -> String {
            "Hello World"
        }
    }

    func testPathBuilder() {
        let pathUUID = UUID()
        let parameter = Parameter<String>(pathUUID)
        let pathComponents: [_PathComponent] = ["test", parameter]
        let endpointParameter1 = EndpointParameter(id: parameter.id, name: nil, label: "pathParam", contentType: String.self, options: parameter.options)
        let endpointParameter2 = EndpointParameter(id: UUID(), name: nil, label: "queryParam", contentType: String.self, options: PropertyOptionSet([.http(.query)]))
        var builder = OpenAPIPathBuilder(pathComponents, parameters: [endpointParameter1, endpointParameter2])

        XCTAssertEqual(builder.path, OpenAPI.Path(stringLiteral: "test/{pathParam}"))
    }

    func testAddPathItem() {
        var componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        var pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &componentsObjectBuilder)
        let endpointParameter = EndpointParameter(id: UUID(), name: nil, label: "queryParam", contentType: String.self, options: PropertyOptionSet([.http(.query)]))
        var endpoint = Endpoint(
                description: "SomeComp",
                context: Context(contextNode: ContextNode()),
                operation: Operation.automatic,
                requestHandler: SharedSemanticModelBuilder.createRequestHandler(with: SomeComp()),
                handleReturnType: SomeComp.Response.self,
                responseType: SomeComp.Response.self,
                parameters: [endpointParameter]
        )
        let endpointTreeNode = EndpointsTreeNode(path: RootPath())
        endpointTreeNode.addEndpoint(&endpoint, at: ["test"])
        pathsObjectBuilder.addPathItem(from: endpoint)
        let path = OpenAPI.Path(stringLiteral: "/test")
        let pathItem = OpenAPI.PathItem(get: OpenAPI.Operation(
                parameters: [Either.parameter(name: "queryParam", context: .query, schema: .string)],
                requestBody: nil,
                responses: [.status(code: 200): .init(OpenAPI.Response(description: "", content: [.txt : .init(schema: .string)]))],
                security: nil))

        XCTAssertEqual(pathsObjectBuilder.pathsObject.count, 1)
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains(key: path))
        XCTAssertTrue(pathsObjectBuilder.pathsObject.contains { (key: OpenAPI.Path, value: OpenAPI.PathItem) -> Bool in key == path && value == pathItem})
        XCTAssertEqual(componentsObjectBuilder.componentsObject.schemas.count, 0)
    }
}
