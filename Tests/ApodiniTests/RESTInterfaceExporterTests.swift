//
// Created by Andi on 25.12.20.
//

@testable import Apodini
@testable import ApodiniREST
import Vapor
import XCTApodini


class RESTInterfaceExporterTests: ApodiniTests {
    lazy var application = Vapor.Application(.testing)

    struct Parameters: Apodini.Content, Decodable, Equatable {
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
        var pathB: String
        var pathBParameter: Parameter<String> {
            _pathB
        }

        @Parameter
        var bird: Bird


        func handle() -> Parameters {
            Parameters(param0: param0, param1: param1, pathA: pathA, pathB: pathB, bird: bird)
        }
    }

    struct User: Apodini.Content, Identifiable, Decodable {
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

    struct DecodedLinksContainer: Decodable {
        var links: [String: String]

        enum CodingKeys: String, CodingKey {
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
        Group {
            "user"
                .hideLink()
                .relationship(name: "user")
            $userId
        } content: {
            UserHandler(userId: $userId)
        }
    }

    func testParameterRetrieval() throws {
        let handler = ParameterRetrievalTestHandler()
        let endpoint = handler.mockEndpoint()

        let exporter = RESTInterfaceExporter(app)
        let context = endpoint.createConnectionContext(for: exporter)

        let body = Bird(name: "Rudi", age: 12)
        let bodyData = ByteBuffer(data: try JSONEncoder().encode(body))

        let uri = URI("http://example.de/test/a/b?param0=value0")

        let request = Vapor.Request(
                application: application,
                method: .POST,
                url: uri,
                collectedBody: bodyData,
                on: app.eventLoopGroup.next()
        )
        // we hardcode the pathId currently here
        request.parameters.set("\(handler.pathAParameter.id)", to: "a")
        request.parameters.set("\(handler.pathBParameter.id)", to: "b")

        try XCTCheckResponse(
            context.handle(request: request),
            content: Parameters(param0: "value0", param1: nil, pathA: "a", pathB: "b", bird: body),
            connectionEffect: .close
        )
    }

    func testRESTRequest() throws {
        let builder = SemanticModelBuilder(app)
            .with(exporter: RESTInterfaceExporter.self)
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
        testService.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.vapor.app.testable(method: .inMemory).test(.GET, "user/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.content.decode(DecodedResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    
    func testEndpointPaths() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                Group("api") {
                    Group("user") {
                        Text("").operation(.read)
                        Text("").operation(.create)
                    }
                }
                Group("api") {
                    Group("post") {
                        Text("").operation(.read)
                    }
                }
            }
        }
        
        let builder = SemanticModelBuilder(app)
            .with(exporter: RESTInterfaceExporter.self)
        WebService().register(builder)
        
        let endpointPaths = builder.rootNode
            .collectEndpoints()
            .map { $0.absolutePath.asPathString() }
        
        let expectedEndpointPaths: [String] = [
            "/v1/api/user", "/v1/api/user", "/v1/api/post"
        ]
        XCTAssert(endpointPaths.compareIgnoringOrder(expectedEndpointPaths))
    }

    @ComponentBuilder
    var webserviceWithoutRoot: some Component {
        Group("test1") {
            Text("Test1")
        }
        Group("test2") {
            Text("Test2")
        }
        Group("test3") {
            Text("Test3")
        }
    }

    func testDefaultRootHandler() throws {
        let builder = SemanticModelBuilder(app)
            .with(exporter: RESTInterfaceExporter.self)
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
        webserviceWithoutRoot.accept(visitor)
        visitor.finishParsing()

        try app.vapor.app.testable(method: .inMemory).test(.GET, "/") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.content.decode(DecodedLinksContainer.self)
            let prefix = "http://127.0.0.1:8080"
            XCTAssertEqual(container.links, ["test1": prefix + "/test1", "test2": prefix + "/test2", "test3": prefix + "/test3"])
        }
    }
}


extension Collection where Element: Hashable {
    /// Returns `true` if the two collections contain the same elements, regardless of their order.
    /// - Note: this is different from `Set(self) == Set(other)`, insofar as this also
    ///         takes into account how often an element occurs, which the Set version would ignore
    func compareIgnoringOrder<S>(_ other: S) -> Bool where S: Collection, S.Element == Element {
        guard self.count == other.count else {
            return false
        }
        return self.countOccurrences() == other.countOccurrences()
    }
    
    
    /// Returns a dictionary containing the dictinct elements of the collection (ie, without duplicates) as the keys, and each element's occurrence count as value
    func countOccurrences() -> [Element: Int] {
        reduce(into: [:]) { result, element in
            result[element] = (result[element] ?? 0) + 1
        }
    }
}
