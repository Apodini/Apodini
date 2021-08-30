//
// Created by Andreas Bauer on 30.08.21.
//

import XCTest
import OpenAPIKit
@testable import Apodini
@testable import ApodiniOpenAPI

final class OpenAPIParameterMetadataTests: ApodiniTests {
    struct TestHandlerQuery: Handler {
        @Parameter var id: String

        func handle() -> String {
            "Hello World"
        }

        var metadata: Metadata {
            ParameterDescription(for: $id, "The user id!")
        }
    }
    
    func testParameterDescription() throws {
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)

        let componentsBuilder = OpenAPIComponentsObjectBuilder()
        var pathsBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: componentsBuilder)

        let handler = TestHandlerQuery()
        handler.accept(visitor)
        visitor.finishParsing()

        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<TestHandlerQuery>)

        pathsBuilder.addPathItem(from: endpoint)

        let document = try XCTUnwrap(pathsBuilder.pathsObject["/"]?.get)
        let parameter = try XCTUnwrap(document.parameters[safe: 0]?.b)

        XCTAssertEqual(parameter.name, "id")
        XCTAssertEqual(parameter.required, true)
        XCTAssertEqual(parameter.description, "The user id!")
    }
}
