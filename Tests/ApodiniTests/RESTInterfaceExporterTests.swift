//
// Created by Andi on 25.12.20.
//

import XCTest
import Vapor
@testable import Apodini

class RESTInterfaceExporterTests: ApodiniTests {
    struct Parameters: Codable {
        var param0: String
        var param1: String?
        var pathA: String
        var pathB: String?
        var bird: Bird
    }

    struct TestRestHandler: Handler {
        @Parameter
        var param0: String
        @Parameter
        var param1: String?

        @Parameter(.http(.path))
        var pathA: String
        var pathAParameter: Parameter<String> {
            _pathA
        }

        @Parameter(.http(.path))
        var pathB: String?
        var pathBParameter: Parameter<String?> {
            _pathB
        }

        @Parameter
        var bird: Bird


        func handle() -> Parameters {
            Parameters(param0: param0, param1: param1, pathA: pathA, pathB: pathB, bird: bird)
        }
    }

    func testParameterRetrieval() throws {
        let handler = TestRestHandler()
        let endpoint = handler.mockEndpoint()

        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)

        let body = Bird(name: "Rudi", age: 12)
        let bodyData = ByteBuffer(data: try JSONEncoder().encode(body))

        let uri = URI("http://example.de/test/a?param0=value0")
        let request = Vapor.Request(
                application: app,
                method: .POST,
                url: uri,
                collectedBody: bodyData,
                on: app.eventLoopGroup.next()
        )
        // we hardcode the pathId currently here
        request.parameters.set(":\(handler.pathAParameter.id)", to: "a")

        let result = try context.handle(request: request)
                .wait()
        let parametersResult: Parameters = try XCTUnwrap(result as? Parameters)

        XCTAssertEqual(parametersResult.param0, "value0")
        XCTAssertEqual(parametersResult.param1, nil)
        XCTAssertEqual(parametersResult.pathA, "a")
        XCTAssertEqual(parametersResult.pathB, nil)
        XCTAssertEqual(parametersResult.bird, body)
    }
}
