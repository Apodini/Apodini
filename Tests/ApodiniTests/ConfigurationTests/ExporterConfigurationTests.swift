//
//  ExporterConfigurationTests.swift
//
//
//  Created by Philipp Zagar on 26.05.21.
//

@testable import Apodini
@testable import ApodiniREST
@testable import ApodiniOpenAPI
import SotoXML
import Vapor
import XCTest
import XCTApodini

extension XMLEncoder: AnyEncoder {
    public func encode<T>(_ value: T) throws -> Data where T: Encodable {
        let element: XML.Element = try self.encode(value)
        return element.xmlString.data(using: .utf8)!
    }
    
    /// Need to implement the encoder() function from the `ContentEncoder` protocol (Vapor) to set XML content type
    public func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders) throws where E: Encodable {
        headers.contentType = .xml
        try body.writeBytes(self.encode(encodable))
    }
}

extension XMLDecoder: AnyDecoder {
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        let xmlElement = try XML.Element(xmlData: data)
        return try self.decode(type, from: xmlElement)
    }
}

// swiftlint:disable type_name
class ExporterConfigurationTests: XCTestCase {
    func testExporterConfigurationWithDefaultEncoderAndDecoder() throws {
        struct TestCollection: ConfigurationCollection {
            var configuration: Configuration {
                RESTInterfaceExporter()
            }
        }

        let testCollection = TestCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 1)
        XCTAssert(configurations[0] is RESTInterfaceExporter)
        XCTAssert((configurations[0] as? RESTInterfaceExporter)?.configuration.encoder is JSONEncoder)
        XCTAssert((configurations[0] as? RESTInterfaceExporter)?.configuration.decoder is JSONDecoder)
        let encoder = (configurations[0] as! RESTInterfaceExporter).configuration.encoder as! JSONEncoder
        XCTAssertTrue(encoder.outputFormatting.contains(.prettyPrinted))
        XCTAssertTrue(encoder.outputFormatting.contains(.withoutEscapingSlashes))
        XCTAssertFalse(encoder.outputFormatting.contains(.sortedKeys))
    }
    
    func testExporterConfigurationWithOwnEncoderAndDecoder() throws {
        struct TestEncoder: AnyEncoder {
            let jsonEncoder = JSONEncoder()
            
            func encode<T>(_ value: T) throws -> Data where T: Encodable {
                try jsonEncoder.encode(value)
            }
        }
        
        struct TestDecoder: AnyDecoder {
            let jsonDecoder = JSONDecoder()
            
            func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
                try jsonDecoder.decode(type, from: data)
            }
        }
        
        struct TestCollection: ConfigurationCollection {
            var configuration: Configuration {
                RESTInterfaceExporter(encoder: TestEncoder(), decoder: TestDecoder())
            }
        }

        let testCollection = TestCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 1)
        XCTAssert(configurations[0] is RESTInterfaceExporter)
        XCTAssert((configurations[0] as? RESTInterfaceExporter)?.configuration.encoder is TestEncoder)
        XCTAssert((configurations[0] as? RESTInterfaceExporter)?.configuration.decoder is TestDecoder)
    }
    
    func testExporterConfigurationWithXMLEncoderAndDecoder() throws {
        struct TestCollection: ConfigurationCollection {
            var configuration: Configuration {
                RESTInterfaceExporter(encoder: XMLEncoder(), decoder: XMLDecoder())
            }
        }

        let testCollection = TestCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 1)
        XCTAssert(configurations[0] is RESTInterfaceExporter)
        XCTAssert((configurations[0] as? RESTInterfaceExporter)?.configuration.encoder is XMLEncoder)
        XCTAssert((configurations[0] as? RESTInterfaceExporter)?.configuration.decoder is XMLDecoder)
    }
}

class RESTExporterConfigurationTests: ApodiniTests {
    lazy var application = Vapor.Application(.testing)

    struct User: Apodini.Content, Identifiable, Decodable {
        let id: String
        let name: String
    }
    
    struct ResponseContainer<Data: Decodable>: Decodable {
        var data: Data
        var links: [String: String]
        
        enum CodingKeys: String, CodingKey {
            case data = "data"
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
    }
    
    struct TestRESTExporterCollection: ConfigurationCollection {
        var configuration: Configuration {
            RESTInterfaceExporter()
        }
    }

    func testRESTRequestWithDefaultEncoderConfig() throws {
        let testCollection = TestRESTExporterCollection()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: app.exporters.semanticModelBuilderBuilder(SemanticModelBuilder(app)))
        testService.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.vapor.app.testable(method: .inMemory).test(.GET, "user/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.content.decode(ResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestRESTExporterCollectionWithJSONEncoderConfig: ConfigurationCollection {
        var configuration: Configuration {
            RESTInterfaceExporter(encoder: JSONEncoder(), decoder: JSONDecoder())
        }
    }

    func testRESTRequestWithWithJSONEncoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithJSONEncoderConfig()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: app.exporters.semanticModelBuilderBuilder(SemanticModelBuilder(app)))
        testService.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.vapor.app.testable(method: .inMemory).test(.GET, "user/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.content.decode(ResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestRESTExporterCollectionWithXMLCoderConfig: ConfigurationCollection {
        var configuration: Configuration {
            RESTInterfaceExporter(encoder: XMLEncoder(), decoder: XMLDecoder())
        }
    }

    func testRESTRequestWithXMLEncoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithXMLCoderConfig()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: app.exporters.semanticModelBuilderBuilder(SemanticModelBuilder(app)))
        testService.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.vapor.app.testable(method: .inMemory).test(.GET, "user/\(userId)?name=\(name)") { res in
            XCTAssertEqual(res.status, .ok)
            let container = try res.content.decode(ResponseContainer<User>.self, using: XMLDecoder())
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct UserHandlerXML: Handler {
        @Parameter(.http(.body))
        var user: User

        func handle() -> User {
            User(id: user.id, name: user.name)
        }
    }

    @ComponentBuilder
    var testServiceXML: some Component {
        Group {
            "user"
                .hideLink()
                .relationship(name: "user")
        } content: {
            UserHandlerXML()
        }
    }
    
    func testRESTResponseWithXMLDecoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithXMLCoderConfig()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: app.exporters.semanticModelBuilderBuilder(SemanticModelBuilder(app)))
        testServiceXML.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        
        try app.vapor.app.testable(method: .inMemory).test(.GET,
                                                           "/user",
                                                           headers: .init(),
                                                           body: ByteBuffer(data: XMLEncoder().encode(User(id: userId, name: name)))) { res in
            XCTAssertEqual(res.status, .ok)
            let container = try res.content.decode(ResponseContainer<User>.self, using: XMLDecoder())
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestRESTExporterCollectionWithJSONEncoderAndXMLDecoderConfig: ConfigurationCollection {
        var configuration: Configuration {
            RESTInterfaceExporter(encoder: JSONEncoder(), decoder: XMLDecoder())
        }
    }
    
    func testRESTResponseWithJSONEncoderAndXMLDecoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithJSONEncoderAndXMLDecoderConfig()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: app.exporters.semanticModelBuilderBuilder(SemanticModelBuilder(app)))
        testServiceXML.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        
        try app.vapor.app.testable(method: .inMemory).test(.GET,
                                                           "/user",
                                                           headers: .init(),
                                                           body: ByteBuffer(data: XMLEncoder().encode(User(id: userId, name: name)))) { res in
            XCTAssertEqual(res.status, .ok)
            let container = try res.content.decode(ResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestRESTExporterCollectionWithXMLEncoderAndJSONDecoderConfig: ConfigurationCollection {
        var configuration: Configuration {
            RESTInterfaceExporter(encoder: XMLEncoder(), decoder: JSONDecoder())
        }
    }
    
    func testRESTResponseWithXMLEncoderAndJSONDecoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithXMLEncoderAndJSONDecoderConfig()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: app.exporters.semanticModelBuilderBuilder(SemanticModelBuilder(app)))
        testServiceXML.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        
        try app.vapor.app.testable(method: .inMemory).test(.GET,
                                                           "/user",
                                                           headers: .init(),
                                                           body: ByteBuffer(data: JSONEncoder().encode(User(id: userId, name: name)))) { res in
            XCTAssertEqual(res.status, .ok)
            let container = try res.content.decode(ResponseContainer<User>.self, using: XMLDecoder())
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestExporterCollectionWithXMLCoderAndOpenAPI: ConfigurationCollection {
        var configuration: Configuration {
            /// Doesn't compile (it shouldn't) -> sometimes weird useless error messages
            //RESTInterfaceExporter(encoder: XMLEncoder(), decoder: JSONDecoder()) {
            RESTInterfaceExporter(encoder: JSONEncoder(), decoder: JSONDecoder()) {
                OpenAPIInterfaceExporter()
            }
        }
    }
}
