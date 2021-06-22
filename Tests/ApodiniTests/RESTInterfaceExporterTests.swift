//
// Created by Andreas Bauer on 25.12.20.
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
        @Binding
        var userId: User.ID
        @Parameter
        var name: String

        func handle() -> User {
            User(id: userId, name: name)
        }
    }

    struct AuthenticatedHandler: Handler {
        func handle() -> User {
            User(id: "2", name: "Name")
        }
    }

    @PathParameter(identifying: User.self)
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
        Group("authenticated") {
            AuthenticatedHandler()
        }
    }
    
    struct TestRESTExporterCollection: ConfigurationCollection {
        var configuration: Configuration {
            REST()
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
        let testCollection = TestRESTExporterCollection()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
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
    
    @ComponentBuilder
    var testServiceCaseSensitive: some Component {
        Group {
            "uSEr"
                .hideLink()
                .relationship(name: "uSEr")
            $userId
        } content: {
            UserHandler(userId: $userId)
        }
    }
    
    struct TestRESTExporterCollectionCaseSensitive: ConfigurationCollection {
        var configuration: Configuration {
            REST(caseInsensitiveRouting: false)
        }
    }
    
    func testRESTRequestCaseSensitive() throws {
        let testCollection = TestRESTExporterCollectionCaseSensitive()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testServiceCaseSensitive.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.vapor.app.testable(method: .inMemory).test(.GET, "uSEr/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.content.decode(DecodedResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    func testRESTRequestCaseSensitive2() throws {
        let testCollection = TestRESTExporterCollectionCaseSensitive()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testServiceCaseSensitive.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.vapor.app.testable(method: .inMemory).test(.GET, "USER/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .notFound)
        }
    }
    
    func testRESTRequestCaseSensitive3() throws {
        let testCollection = TestRESTExporterCollectionCaseSensitive()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testServiceCaseSensitive.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.vapor.app.testable(method: .inMemory).test(.GET, "user/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .notFound)
        }
    }
    
    // swiftlint:disable type_name
    struct TestRESTExporterCollectionCaseInsensitive: ConfigurationCollection {
        var configuration: Configuration {
            REST(caseInsensitiveRouting: true)
        }
    }
    
    func testRESTRequestCaseInsensitive() throws {
        let testCollection = TestRESTExporterCollectionCaseInsensitive()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testServiceCaseSensitive.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.vapor.app.testable(method: .inMemory).test(.GET, "uSEr/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.content.decode(DecodedResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    func testRESTRequestCaseInsensitive2() throws {
        let testCollection = TestRESTExporterCollectionCaseInsensitive()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testServiceCaseSensitive.accept(visitor)
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
    
    func testRESTRequestCaseInsensitive3() throws {
        let testCollection = TestRESTExporterCollectionCaseInsensitive()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testServiceCaseSensitive.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.vapor.app.testable(method: .inMemory).test(.GET, "uSEr/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.content.decode(DecodedResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    func testRESTRequestCaseInsensitive4() throws {
        let testCollection = TestRESTExporterCollectionCaseInsensitive()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testServiceCaseSensitive.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.vapor.app.testable(method: .inMemory).test(.GET, "uSErA/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .notFound)
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
        
        let testCollection = TestRESTExporterCollection()
        testCollection.configuration.configure(app)
        let builder = SemanticModelBuilder(app)
        WebService().register(builder)
        
        let endpointPaths = builder.collectedEndpoints.map { $0.absoluteRESTPath.asPathString() }.sorted()
        
        let expectedEndpointPaths: [String] = [
            "/v1/api/user", "/v1/api/user", "/v1/api/post"
        ].sorted()
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
        let testCollection = TestRESTExporterCollection()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
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
