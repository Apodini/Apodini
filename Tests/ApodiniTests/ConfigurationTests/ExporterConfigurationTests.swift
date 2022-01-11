//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
@testable import ApodiniREST
import ApodiniUtils
@testable import ApodiniOpenAPI
import SotoXML
import XCTest
import XCTApodini
import ApodiniNetworking
import XCTApodiniNetworking


extension XMLEncoder: ApodiniUtils.AnyEncoder {
    public var resultMediaTypeRawValue: String? {
        HTTPMediaType.xml.encodeToHTTPHeaderFieldValue()
    }
    
    public func encode<T>(_ value: T) throws -> Data where T: Encodable {
        let element: XML.Element = try self.encode(value)
        return element.xmlString.data(using: .utf8)!
    }
}

extension XMLDecoder: ApodiniUtils.AnyDecoder {
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        let xmlElement = try XML.Element(xmlData: data)
        return try self.decode(type, from: xmlElement)
    }
}

// swiftlint:disable type_name
class ExporterConfigurationTests: ApodiniTests {
    func testExporterConfigurationWithDefaultEncoderAndDecoder() throws {
        struct TestCollection: ConfigurationCollection {
            var configuration: Configuration {
                REST()
            }
        }

        let testCollection = TestCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 1)
        XCTAssert(configurations[0] is REST)
        XCTAssert((configurations[0] as? REST)?.configuration.encoder is JSONEncoder)
        XCTAssert((configurations[0] as? REST)?.configuration.decoder is JSONDecoder)
        let encoder = (configurations[0] as! REST).configuration.encoder as! JSONEncoder
        XCTAssertTrue(encoder.outputFormatting.contains(.prettyPrinted))
        XCTAssertTrue(encoder.outputFormatting.contains(.withoutEscapingSlashes))
        XCTAssertFalse(encoder.outputFormatting.contains(.sortedKeys))
    }
    
    func testExporterConfigurationWithOwnEncoderAndDecoder() throws {
        struct TestEncoder: ApodiniUtils.AnyEncoder {
            var resultMediaTypeRawValue: String? { "application/x-apodini-json" }
            let jsonEncoder = JSONEncoder()
            
            func encode<T>(_ value: T) throws -> Data where T: Encodable {
                try jsonEncoder.encode(value)
            }
        }
        
        struct TestDecoder: ApodiniUtils.AnyDecoder {
            let jsonDecoder = JSONDecoder()
            
            func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
                try jsonDecoder.decode(type, from: data)
            }
        }
        
        struct TestCollection: ConfigurationCollection {
            var configuration: Configuration {
                REST(encoder: TestEncoder(), decoder: TestDecoder())
            }
        }

        let testCollection = TestCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 1)
        XCTAssert(configurations[0] is REST)
        XCTAssert((configurations[0] as? REST)?.configuration.encoder is TestEncoder)
        XCTAssert((configurations[0] as? REST)?.configuration.decoder is TestDecoder)
        
        struct TestWebService: Apodini.WebService {
            var content: some Component {
                Text("Servus")
            }
            var configuration: Configuration {
                REST(encoder: TestEncoder(), decoder: TestDecoder())
            }
        }
        
        TestWebService().start(app: app)
        
        try app.testable().test(.GET, "/") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(response.headers[.contentType], HTTPMediaType(type: "application", subtype: "x-apodini-json"))
            XCTAssertEqual("Servus", try XCTUnwrapRESTResponseData(String.self, from: response))
        }
    }
    
    func testExporterConfigurationWithXMLEncoderAndDecoder() throws {
        struct TestCollection: ConfigurationCollection {
            var configuration: Configuration {
                REST(encoder: XMLEncoder(), decoder: XMLDecoder())
            }
        }

        let testCollection = TestCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 1)
        XCTAssert(configurations[0] is REST)
        XCTAssert((configurations[0] as? REST)?.configuration.encoder is XMLEncoder)
        XCTAssert((configurations[0] as? REST)?.configuration.decoder is XMLDecoder)
    }
}


class RESTExporterConfigurationTests: ApodiniTests {
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
            REST()
        }
    }

    func testRESTRequestWithDefaultEncoderConfig() throws {
        let testCollection = TestRESTExporterCollection()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testService.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.testable().test(.GET, "user/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.bodyStorage.getFullBodyData(decodedAs: ResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestRESTExporterCollectionWithJSONEncoderConfig: ConfigurationCollection {
        var configuration: Configuration {
            REST(encoder: JSONEncoder(), decoder: JSONDecoder())
        }
    }

    func testRESTRequestWithWithJSONEncoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithJSONEncoderConfig()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testService.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.testable().test(.GET, "user/\(userId)?name=\(name)") { response in
            XCTAssertEqual(response.status, .ok)
            let container = try response.bodyStorage.getFullBodyData(decodedAs: ResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestRESTExporterCollectionWithXMLCoderConfig: ConfigurationCollection {
        var configuration: Configuration {
            REST(encoder: XMLEncoder(), decoder: XMLDecoder())
        }
    }

    func testRESTRequestWithXMLEncoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithXMLCoderConfig()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testService.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        try app.testable().test(.GET, "user/\(userId)?name=\(name)") { res in
            XCTAssertEqual(res.status, .ok)
            let container = try res.bodyStorage.getFullBodyData(decodedAs: ResponseContainer<User>.self, using: XMLDecoder())
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
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testServiceXML.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        let user = User(id: userId, name: name)
        try app.testable().test(.GET, "/user", body: .init(data: XMLEncoder().encode(user))) { res in
            XCTAssertEqual(res.status, .ok)
            let container = try res.bodyStorage.getFullBodyData(decodedAs: ResponseContainer<User>.self, using: XMLDecoder())
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestRESTExporterCollectionWithJSONEncoderAndXMLDecoderConfig: ConfigurationCollection {
        var configuration: Configuration {
            REST(encoder: JSONEncoder(), decoder: XMLDecoder())
        }
    }
    
    func testRESTResponseWithJSONEncoderAndXMLDecoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithJSONEncoderAndXMLDecoderConfig()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testServiceXML.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        
        let user = User(id: userId, name: name)
        try app.testable().test(.GET, "/user", body: .init(data: XMLEncoder().encode(user))) { res in
            XCTAssertEqual(res.status, .ok)
            let container = try res.bodyStorage.getFullBodyData(decodedAs: ResponseContainer<User>.self)
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestRESTExporterCollectionWithXMLEncoderAndJSONDecoderConfig: ConfigurationCollection {
        var configuration: Configuration {
            REST(encoder: XMLEncoder(), decoder: JSONDecoder())
        }
    }
    
    func testRESTResponseWithXMLEncoderAndJSONDecoderConfig() throws {
        let testCollection = TestRESTExporterCollectionWithXMLEncoderAndJSONDecoderConfig()
        testCollection.configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        testServiceXML.accept(visitor)
        visitor.finishParsing()

        let userId = "1234"
        let name = "Rudi"
        
        try app.testable().test(.GET, "/user", body: .init(data: JSONEncoder().encode(User(id: userId, name: name)))) { res in
            XCTAssertEqual(res.status, .ok)
            let container = try res.bodyStorage.getFullBodyData(decodedAs: ResponseContainer<User>.self, using: XMLDecoder())
            XCTAssertEqual(container.data.id, userId)
            XCTAssertEqual(container.data.name, name)
        }
    }
    
    struct TestExporterCollectionWithXMLCoderAndOpenAPI: ConfigurationCollection {
        var configuration: Configuration {
            // Doesn't compile (it shouldn't) -> sometimes weird useless error messages
            //REST(encoder: XMLEncoder(), decoder: JSONDecoder()) {
            REST(encoder: JSONEncoder(), decoder: JSONDecoder()) {
                OpenAPI()
            }
        }
    }
}
