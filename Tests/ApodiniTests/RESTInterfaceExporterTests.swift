//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
@testable import ApodiniREST
import ApodiniNetworking
import XCTApodini
import XCTApodiniNetworking


class RESTInterfaceExporterTests: ApodiniTests {
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

    struct ThrowingHandler: Handler {
        @Throws(.serverError) var error: ApodiniError
        @Parameter var doThrow = true

        func handle() throws -> Never {
            throw error
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
        Group("throwing") {
            ThrowingHandler()
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
        
        let request = HTTPRequest(
            method: .POST,
            url: "http://example.de/test/a/b?param0=value0",
            bodyStorage: .buffer(bodyData),
            eventLoop: app.eventLoopGroup.next()
        )
        // we hardcode the pathId currently here
        request.setParameter(for: "\(handler.pathAParameter.id)", to: "a")
        request.setParameter(for: "\(handler.pathBParameter.id)", to: "b")

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
        try app.testable().test(.GET, "user/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.bodyStorage.getFullBodyData(decodedAs: DecodedResponseContainer<User>.self)
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
        try app.testable().test(.GET, "uSEr/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.bodyStorage.getFullBodyData(decodedAs: DecodedResponseContainer<User>.self)
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
        try app.testable().test(.GET, "USER/\(userId)?name=\(name)") { response in
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
        try app.testable().test(.GET, "user/\(userId)?name=\(name)") { response in
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
        try app.testable().test(.GET, "uSEr/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.bodyStorage.getFullBodyData(decodedAs: DecodedResponseContainer<User>.self)
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
        try app.testable().test(.GET, "user/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.bodyStorage.getFullBodyData(decodedAs: DecodedResponseContainer<User>.self)
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
        try app.testable().test(.GET, "uSEr/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.bodyStorage.getFullBodyData(decodedAs: DecodedResponseContainer<User>.self)
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
        try app.testable().test(.GET, "uSErA/\(userId)?name=\(name)") { response in
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

        try app.testable().test(.GET, "/") { response in
            XCTAssertEqual(response.status, .ok)
            //let linksContainer = try XCTUnwrap((XCTUnwrapRESTResponse(Void.self, from: response).links
            //let container = try response.content.decode(DecodedLinksContainer.self)
            let container = try response.bodyStorage.getFullBodyData(decodedAs: DecodedLinksContainer.self, using: JSONDecoder())
            let prefix = "http://localhost"
            XCTAssertEqual(container.links, ["test1": prefix + "/test1", "test2": prefix + "/test2", "test3": prefix + "/test3"])
        }
    }

    func testInformation() throws {
        let authToken = "UGF1bFNjaG1pZWRtYXllcjpTdXBlclNlY3JldFBhc3N3b3Jk"
        let value = "Basic UGF1bFNjaG1pZWRtYXllcjpTdXBlclNlY3JldFBhc3N3b3Jk"
        
        let headers = HTTPHeaders {
            $0[.authorization] = .basic(credentials: authToken)
        }

        let request = HTTPRequest(method: .GET, url: "/", headers: headers, eventLoop: app.eventLoopGroup.next())

        var information = request.information
        information.insert(ETag("someTag", isWeak: true))

        let authorization = try XCTUnwrap(information[Authorization.self])
        XCTAssertEqual(authorization.type, "Basic")
        XCTAssertEqual(authorization.credentials, "UGF1bFNjaG1pZWRtYXllcjpTdXBlclNlY3JldFBhc3N3b3Jk")
        XCTAssertEqual(authorization.basic?.username, "PaulSchmiedmayer")
        XCTAssertEqual(authorization.basic?.password, "SuperSecretPassword")
        XCTAssertNil(authorization.bearerToken)

        let restoredHeaders = HTTPHeaders(information)
        XCTAssertEqual(restoredHeaders[.authorization], .basic(credentials: authToken))
        XCTAssertEqual(restoredHeaders.first(name: AnyHTTPHeaderName.authorization.rawValue), value)
        XCTAssertEqual(restoredHeaders[.eTag], .weak("W/\"someTag\""))
        XCTAssertEqual(restoredHeaders.first(name: AnyHTTPHeaderName.eTag.rawValue), "W/\"someTag\"")
    }
    
    func testRESTInformation() throws {
        struct InformationHandler: Handler {
            func handle() -> Apodini.Response<String> {
                Response.send(
                    "Paul",
                    status: .created,
                    information: [AnyHTTPInformation(key: "Test", rawValue: "Test")]
                )
            }
        }
        
        struct TestWebService: WebService {
            var content: some Component {
                InformationHandler()
            }
            
            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService().start(app: app)

        try app.testable().test(.GET, "/v1/") { response in
            XCTAssertEqual(response.headers[.contentType], HTTPMediaType.json)
            XCTAssertEqual(response.headers["Test"], ["Test"])
            XCTAssertEqual(response.status, .created)
            let responseJSON = try XCTUnwrapRESTResponse(String.self, from: response)
            XCTAssertEqual(responseJSON, WrappedRESTResponse<String>(data: "Paul", links: ["self": "http://localhost/v1"]))
        }
    }
    
    func testRESTBlobInformation() throws {
        struct BlobInformationHandler: Handler {
            func handle() -> Apodini.Response<Blob> {
                Response.send(
                    Blob(ByteBuffer(), type: .application(.pdf)),
                    status: .created,
                    information: [AnyHTTPInformation(key: "Test", rawValue: "Test")]
                )
            }
        }
        
        struct TestWebService: WebService {
            var content: some Component {
                BlobInformationHandler()
            }
            
            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService().start(app: app)

        try app.testable().test(.GET, "/v1/") { response in
            XCTAssertEqual(response.headers[.contentType], .pdf)
            XCTAssertEqual(response.headers["Content-Type"].first, "application/pdf")
            XCTAssertEqual(response.headers["Test"], ["Test"])
            XCTAssertEqual(response.status, .created)
            XCTAssertEqual(response.bodyStorage.readableBytes, 0)
        }
    }

    func testDecodingErrorForwarding() throws {
        var forwardedError: Error?
        let errorForwardingExporter = ErrorForwardingInterfaceExporter {
            forwardedError = $0
        }
        app.registerExporter(exporter: errorForwardingExporter)

        let testCollection = TestRESTExporterCollection()
        testCollection.configuration.configure(app)

        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testService.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        try app.testable().test(.GET, "user/\(userId)") { response in
            XCTAssertEqual(response.status, .internalServerError)
            let apodiniError = try XCTUnwrap(forwardedError as? ApodiniError)
            XCTAssertEqual(apodiniError.option(for: .errorType), .badInput)
        }
    }

    func testEvaluationErrorForwarding() throws {
        var forwardedError: Error?
        let errorForwardingExporter = ErrorForwardingInterfaceExporter {
            forwardedError = $0
        }
        app.registerExporter(exporter: errorForwardingExporter)

        let testCollection = TestRESTExporterCollection()
        testCollection.configuration.configure(app)

        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testService.accept(visitor)
        visitor.finishParsing()

        try app.testable().test(.GET, "throwing") { response in
            XCTAssertEqual(response.status, .internalServerError)
            let apodiniError = try XCTUnwrap(forwardedError as? ApodiniError)
            XCTAssertEqual(apodiniError.option(for: .errorType), .serverError)
        }
    }
}
