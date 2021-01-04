//
// Created by Andi on 25.12.20.
//

import XCTest
import Vapor
@testable import Apodini

class RESTInterfaceExporterTests: ApodiniTests {
    struct Parameters: Encodable, Apodini.Response {
        var param0: String
        var param1: String?
        var pathA: String
        var pathB: String?
        var bird: Bird
    }

    struct ParameterRetrievalTestHandler: Handler {
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

    struct User: Codable, Apodini.Response, Identifiable {
        let id: String
        let name: String
    }
    
    struct DecodedResponseContainer<Data: Decodable>: Decodable {
        var data: Data
        var links: [String: String]
        
        enum CodingKeys: String, CodingKey {
            case data = "data"
            case links = "_links"
        }
    }

    struct UserHandler: Handler {
        @Parameter
        var userId: User.ID
        @Parameter
        var name: String

        func handle() -> User {
            User(id: userId, name: name)
        }
    }

    @PathParameter
    var userId: User.ID

    @ComponentBuilder
    var testService: some Component {
        Group("user", $userId) {
            UserHandler(userId: $userId)
        }
    }

    func testParameterRetrieval() throws {
        let handler = ParameterRetrievalTestHandler()
        let endpoint = handler.mockEndpoint()

        let exporter = RESTInterfaceExporter(app)
        let requestHandler = endpoint.createRequestHandler(for: exporter)

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

        let result = try requestHandler(request: request)
                .wait()
        guard case let .automatic(responseValue) = result.typed(Parameters.self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        
        XCTAssertEqual(responseValue.param0, "value0")
        XCTAssertEqual(responseValue.param1, nil)
        XCTAssertEqual(responseValue.pathA, "a")
        XCTAssertEqual(responseValue.pathB, nil)
        XCTAssertEqual(responseValue.bird, body)
    }

    func testRESTRequest() throws {
        let builder = SharedSemanticModelBuilder(app)
            .with(exporter: RESTInterfaceExporter.self)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [builder])
        testService.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.testable(method: .inMemory).test(.GET, "user/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.content.decode(DecodedResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
}
