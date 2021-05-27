//
//  ExporterConfigurationTests.swift
//  
//
//  Created by Philipp Zagar on 26.05.21.
//

@testable import Apodini
@testable import ApodiniREST
@testable import SotoXML
import ApodiniUtils
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

class ExporterConfigurationTests: XCTestCase {
    func testExporterConfigurationWithDefaultEncoderAndDecoder() throws {
        struct TestCollection: ConfigurationCollection {
            var configuration: Configuration {
                _RESTInterfaceExporter()
            }
        }

        let testCollection = TestCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 1)
        XCTAssert(configurations[0] is _RESTInterfaceExporter)
        XCTAssert((configurations[0] as? _RESTInterfaceExporter)?.configuration.encoder is JSONEncoder)
        XCTAssert((configurations[0] as? _RESTInterfaceExporter)?.configuration.decoder is JSONDecoder)
        XCTAssertTrue((((configurations[0] as! _RESTInterfaceExporter).configuration.encoder as! JSONEncoder).outputFormatting.contains(.prettyPrinted)))
        XCTAssertTrue((((configurations[0] as! _RESTInterfaceExporter).configuration.encoder as! JSONEncoder).outputFormatting.contains(.withoutEscapingSlashes)))
        XCTAssertFalse((((configurations[0] as! _RESTInterfaceExporter).configuration.encoder as! JSONEncoder).outputFormatting.contains(.sortedKeys)))
    }
    
    func testExporterConfigurationWithOwnEncoderAndDecoder() throws {
        struct TestEncoder: AnyEncoder {
            let jsonEncoder: JSONEncoder = JSONEncoder()
            
            func encode<T>(_ value: T) throws -> Data where T : Encodable {
                return try jsonEncoder.encode(value)
            }
        }
        
        struct TestDecoder: AnyDecoder {
            let jsonDecoder: JSONDecoder = JSONDecoder()
            
            func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
                return try jsonDecoder.decode(type, from: data)
            }
        }
        
        struct TestCollection: ConfigurationCollection {
            var configuration: Configuration {
                _RESTInterfaceExporter(encoder: TestEncoder(), decoder: TestDecoder())
            }
        }

        let testCollection = TestCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 1)
        XCTAssert(configurations[0] is _RESTInterfaceExporter)
        XCTAssert((configurations[0] as? _RESTInterfaceExporter)?.configuration.encoder is TestEncoder)
        XCTAssert((configurations[0] as? _RESTInterfaceExporter)?.configuration.decoder is TestDecoder)
    }
    
    func testExporterConfigurationWithXMLEncoderAndDecoder() throws {
        struct TestCollection: ConfigurationCollection {
            var configuration: Configuration {
                _RESTInterfaceExporter(encoder: XMLEncoder(), decoder: XMLDecoder())
            }
        }

        let testCollection = TestCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 1)
        XCTAssert(configurations[0] is _RESTInterfaceExporter)
        XCTAssert((configurations[0] as? _RESTInterfaceExporter)?.configuration.encoder is XMLEncoder)
        XCTAssert((configurations[0] as? _RESTInterfaceExporter)?.configuration.decoder is XMLDecoder)
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
            _RESTInterfaceExporter()
        }
    }

    func testRESTRequestWithDefaultEncoderConfig() throws {
        let testCollection = TestRESTExporterCollection()
        let builder = SemanticModelBuilder(app)
        testCollection.configuration.configure(app, builder)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
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
            _RESTInterfaceExporter(encoder: JSONEncoder(), decoder: JSONDecoder())
        }
    }

    func testRESTRequestWithWithJSONEncoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithJSONEncoderConfig()
        let builder = SemanticModelBuilder(app)
        testCollection.configuration.configure(app, builder)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
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
            _RESTInterfaceExporter(encoder: XMLEncoder(), decoder: XMLDecoder())
        }
    }

    func testRESTRequestWithXMLEncoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithXMLCoderConfig()
        let builder = SemanticModelBuilder(app)
        testCollection.configuration.configure(app, builder)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
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
        let builder = SemanticModelBuilder(app)
        testCollection.configuration.configure(app, builder)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
        testServiceXML.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/user",
                                                           headers: .init(),
                                                           body: ByteBuffer(data: XMLEncoder().encode(User(id: userId, name: name))))
        { res in
            XCTAssertEqual(res.status, .ok)
            let container = try res.content.decode(ResponseContainer<User>.self, using: XMLDecoder())
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestRESTExporterCollectionWithJSONEncoderAndXMLDecoderConfig: ConfigurationCollection {
        var configuration: Configuration {
            _RESTInterfaceExporter(encoder: JSONEncoder(), decoder: XMLDecoder())
        }
    }
    
    func testRESTResponseWithJSONEncoderAndXMLDecoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithJSONEncoderAndXMLDecoderConfig()
        let builder = SemanticModelBuilder(app)
        testCollection.configuration.configure(app, builder)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
        testServiceXML.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/user",
                                                           headers: .init(),
                                                           body: ByteBuffer(data: XMLEncoder().encode(User(id: userId, name: name))))
        { res in
            XCTAssertEqual(res.status, .ok)
            let container = try res.content.decode(ResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestRESTExporterCollectionWithXMLEncoderAndJSONDecoderConfig: ConfigurationCollection {
        var configuration: Configuration {
            _RESTInterfaceExporter(encoder: XMLEncoder(), decoder: JSONDecoder())
        }
    }
    
    func testRESTResponseWithXMLEncoderAndJSONDecoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithXMLEncoderAndJSONDecoderConfig()
        let builder = SemanticModelBuilder(app)
        testCollection.configuration.configure(app, builder)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
        testServiceXML.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        
        try app.vapor.app.testable(method: .inMemory).test(.GET, "/user",
                                                           headers: .init(),
                                                           body: ByteBuffer(data: JSONEncoder().encode(User(id: userId, name: name))))
        { res in
            XCTAssertEqual(res.status, .ok)
            let container = try res.content.decode(ResponseContainer<User>.self, using: XMLDecoder())
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
}
