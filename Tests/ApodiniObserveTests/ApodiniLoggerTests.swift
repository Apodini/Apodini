//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import XCTApodini
import XCTApodiniNetworking
@testable import Logging
@testable import ApodiniObserve
import ApodiniHTTP
@testable import Apodini
@testable import SwiftLogTesting


// swiftlint:disable closure_body_length
class ApodiniLoggerTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    static var app: Apodini.Application!
    
    static let loggingLabel = "logger.test"
    static let loggerUUID = UUID()
    
    override class func setUp() {
        super.setUp()
        
        app = Application()
        configuration.configure(app)
        app = Self.configureLogger(app, loggerConfiguration: LoggerConfiguration(logHandlers: TestingLogHandler.init, logLevel: .info))
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        content.accept(visitor)
        visitor.finishParsing()
    }
    
    override class func tearDown() {
        super.tearDown()
        
        app.shutdown()
        
        XCTAssertApodiniApplicationNotRunning()
    }
    
    // Copied from the source code of ApodiniObserve to bootstrap the LoggingSystem internally
    // (required for the tests, as the LoggingSystem only allows to be configured once per process)
    static func configureLogger(_ app: Apodini.Application, loggerConfiguration: LoggerConfiguration) -> Apodini.Application {
        // Bootstrap the logging system
        LoggingSystem.bootstrapInternal { label in
            MultiplexLogHandler(
                loggerConfiguration.logHandlers.map { logHandler in
                    logHandler(label)
                }
            )
        }
        
        if !app.checkRegisteredExporter(exporterType: ObserveMetadataExporter.self) {
            // Instanciate exporter
            let metadataExporter = ObserveMetadataExporter(app, loggerConfiguration)
            
            // Insert exporter into `InterfaceExporterStorage`
            app.registerExporter(exporter: metadataExporter)
        }
        
        // Write configuration to the storage
        app.storage.set(
            LoggerConfiguration.LoggingStorageKey.self,
            to: LoggerConfiguration.LoggingStorageValue(logger: app.logger, configuration: loggerConfiguration)
        )
        
        return app
    }
    
    static var requestResponseHandler1Line: UInt!
    
    struct RequestResponse: Handler {
        @Parameter(.http(.path)) var name: String
        
        @Parameter(.http(.query)) var greeting: String?
        
        @ApodiniLogger(label: ApodiniLoggerTests.loggingLabel) var logger

        func handle() -> String {
            logger.info("Hello world!")
            requestResponseHandler1Line = #line - 1
            return "\(greeting ?? "Hello"), \(name)!"
        }
    }
    
    static var requestResponseHandler2Line: UInt!
    
    struct RequestResponse2: Handler {
        @Parameter(.http(.path)) var name: String
        
        @Parameter(.http(.query)) var greeting: String?
        
        @ApodiniLogger(id: ApodiniLoggerTests.loggerUUID,
                       label: ApodiniLoggerTests.loggingLabel,
                       logLevel: .debug,
                       metadataLevel: .reduced,
                       logHandler: TestingLogHandler.init)
        var logger

        func handle() -> String {
            logger.debug("Hello world!")
            requestResponseHandler2Line = #line - 1
            return "\(greeting ?? "Hello"), \(name)!"
        }
    }
    
    static var requestResponseHandler3Line: UInt!
    
    struct RequestResponse3: Handler {
        @Parameter(.http(.path)) var name: String
        
        @Parameter(.http(.query)) var greeting: String?
        
        @ApodiniLogger(id: ApodiniLoggerTests.loggerUUID,
                       label: ApodiniLoggerTests.loggingLabel,
                       metadataLevel: .none)
        var logger

        func handle() -> String {
            logger.info("Hello world!")
            requestResponseHandler3Line = #line - 1
            return "\(greeting ?? "Hello"), \(name)!"
        }
    }
    
    static var requestResponseHandler4Line: UInt!
    
    struct RequestResponse4: Handler {
        @Parameter(.http(.path)) var name: String
        
        @Parameter(.http(.query)) var greeting: String?
        
        @ApodiniLogger(label: ApodiniLoggerTests.loggingLabel,
                       metadataLevel: .custom(metadata: ["endpoint"]))
        var logger

        func handle() -> String {
            logger.info("Hello world!")
            requestResponseHandler4Line = #line - 1
            return "\(greeting ?? "Hello"), \(name)!"
        }
    }
    
    static var requestResponseHandler5Line: UInt!
    
    struct RequestResponse5: Handler {
        @Parameter(.http(.body)) var complexParameter: ComplexParameter
        
        @ApodiniLogger(label: ApodiniLoggerTests.loggingLabel,
                       metadataLevel: .custom(metadata: ["request"]))
        var logger

        func handle() -> String {
            logger.info("Hello world!")
            requestResponseHandler5Line = #line - 1
            return "Hi whats up?!"
        }
    }
    
    struct ComplexParameter: Codable, Equatable {
        var string: String
        var int: Int
        var double: Double
        var bool: Bool
        var array: [String]
        var dictionary: [Int: String]
    }
    
    class FakeTimer: Apodini.ObservableObject {
        @Apodini.Published private var _trigger = true
        
        init() {  }
        
        func secondPassed() {
            _trigger.toggle()
        }
    }
    
    static var serverSideStreamingHandlerStreamingLine: UInt!
    static var serverSideStreamingHandlerFinalLine: UInt!

    struct ServerSideStreaming: Handler {
        @Parameter(.http(.query), .mutability(.constant)) var start: Int = 10
        
        @State var counter = -1
        
        @ObservedObject var timer = FakeTimer()
        
        @ApodiniLogger(label: ApodiniLoggerTests.loggingLabel) var logger
        
        func handle() -> Apodini.Response<Blob> {
            timer.secondPassed()
            counter += 1
            
            if counter == start {
                logger.info("Hello world - Launch!")
                serverSideStreamingHandlerFinalLine = #line - 1
                return .final(.init("🚀🚀🚀 Launch !!! 🚀🚀🚀\n".data(using: .utf8)!, type: .text(.plain)))
            } else {
                logger.info("Hello world - Countdown!")
                serverSideStreamingHandlerStreamingLine = #line - 1
                return .send(.init("\(start - counter)...\n".data(using: .utf8)!, type: .text(.plain)))
            }
        }
        
        
        var metadata: AnyHandlerMetadata {
            Pattern(.serviceSideStream)
        }
    }
    
    static var clientSideStreamingHandlerStreamingLine: UInt!
    static var clientSideStreamingHandlerFinalLine: UInt!
    
    struct ClientSideStreaming: Handler {
        @Parameter(.http(.query)) var country: String?
        
        @Apodini.Environment(\.connection) var connection
        
        @State var list: [String] = []
        
        @ApodiniLogger(label: ApodiniLoggerTests.loggingLabel) var logger
        
        func handle() -> Apodini.Response<String> {
            switch connection.state {
            case .open:
                list.append(country ?? "the World")
                logger.info("Hello world - Streaming!")
                clientSideStreamingHandlerStreamingLine = #line - 1
                return .nothing
            case .end, .close:
                var response = "Hello, " + list[0..<list.count - 1].joined(separator: ", ")
                if let last = list.last {
                    response += " and " + last
                } else {
                    response += "everyone"
                }
                logger.info("Hello world - End!")
                clientSideStreamingHandlerFinalLine = #line - 1
                return .final(response + "!")
            }
        }
        
        var metadata: AnyHandlerMetadata {
            Pattern(.clientSideStream)
        }
    }
    
    static var bidirectionalStreamingHandlerStreamingLine: UInt! // swiftlint:disable:this identifier_name
    static var bidirectionalStreamingHandlerFinalLine: UInt!

    struct BidirectionalStreaming: Handler {
        @Parameter(.http(.query)) var country: String?
        
        @Apodini.Environment(\.connection) var connection
        
        @ApodiniLogger(label: ApodiniLoggerTests.loggingLabel) var logger
        
        func handle() -> Apodini.Response<String> {
            switch connection.state {
            case .open:
                logger.info("Hello world - Streaming!")
                bidirectionalStreamingHandlerStreamingLine = #line - 1
                return .send("Hello, \(country ?? "World")!")
            case .end, .close:
                logger.info("Hello world - End!")
                bidirectionalStreamingHandlerFinalLine = #line - 1
                return .end
            }
        }
        
        var metadata: AnyHandlerMetadata {
            Pattern(.bidirectionalStream)
        }
    }

    @ConfigurationBuilder
    static var configuration: Configuration {
        HTTP()
    }

    @ComponentBuilder
    static var content: some Component {
        Group("requestResponse") {
            RequestResponse()
        }
        Group("requestResponse2") {
            RequestResponse2()
        }
        Group("requestResponse3") {
            RequestResponse3()
        }
        Group("requestResponse4") {
            RequestResponse4()
        }
        Group("requestResponse5") {
            RequestResponse5()
        }
        Group("serverSideStreaming") {
            ServerSideStreaming()
        }
        Group("clientSideStreaming") {
            ClientSideStreaming()
        }
        Group("bidirectionalStreaming") {
            BidirectionalStreaming()
        }
    }

    func testRequestResponsePattern() throws {
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        try Self.app.testable().test(.GET, "/requestResponse/Philipp") { response in
            XCTAssertEqual(1, container.messages.count)
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world!")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file, #file)
            XCTAssertEqual(logMessage.function, "handle()")
            XCTAssertEqual(logMessage.line, Self.requestResponseHandler1Line)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            let exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array([
                .string("[lightweight]"), .string("[content]"), .string("[path]")
            ]))
            
            // Request metdata
            let requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(10, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /requestResponse/:name"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["greeting"]), .string("nil"))
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/requestResponse/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/requestResponse/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://127.0.0.1:8000/requestResponse/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/requestResponse/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/requestResponse/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPBody"]), .string(""))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPContentType"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPVersion"]), .string("HTTP/1.1"))
            
            // Connection metadata
            let connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["remoteAddress"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("end"))
            XCTAssertNotNil(connectionMetadata["eventLoop"])
            
            
            // Logger UUID metadata
            XCTAssertNotNil(metadata["logger-uuid"])
            
            // Endpoint metadata
            let endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(8, endpointMetadata.count)
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array(
                [
                    .string("@Parameter(HTTPParameterMode = .path) var name: String"),
                    .string("@Parameter(HTTPParameterMode = .query) var greeting: String?")
                ]
            ))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/requestResponse"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("RequestResponse"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("RequestResponse"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("requestResponse"))
            
            // Information metadata
            let informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
            XCTAssertEqual(0, informationMetadata.count)
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Hello, Philipp!")
        }
        
        container.reset()
        
        try Self.app.testable().test(.GET, "/requestResponse/Paul?greeting=Hi") { response in
            let logMessage = container.messages[0]
            let metadata = try XCTUnwrap(logMessage.metadata)
            let requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["greeting"]), .string("Hi"))
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Paul"))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Hi, Paul!")
        }
        
        container.reset()
    }
    
    func testRequestResponsePattern2() throws {
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        try Self.app.testable().test(.GET, "/requestResponse2/Philipp") { response in
            XCTAssertEqual(1, container.messages.count)
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world!")
            XCTAssertEqual(logMessage.level, .debug)
            XCTAssertEqual(logMessage.file, #file)
            XCTAssertEqual(logMessage.function, "handle()")
            XCTAssertEqual(logMessage.line, Self.requestResponseHandler2Line)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(4, metadata.count)
            
            // Exporter metadata
            let exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array(
                [
                    .string("[lightweight]"),
                    .string("[content]"),
                    .string("[path]")
                ]
            ))
            
            // Request metdata
            let requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(10, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /requestResponse2/:name"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["greeting"]), .string("nil"))
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/requestResponse2/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/requestResponse2/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://127.0.0.1:8000/requestResponse2/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/requestResponse2/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/requestResponse2/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPBody"]), .string(""))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPContentType"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPVersion"]), .string("HTTP/1.1"))
            
            // Logger UUID metadata
            XCTAssertNotNil(metadata["logger-uuid"])
            
            // Endpoint metadata
            let endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(8, endpointMetadata.count)
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array(
                [
                    .string("@Parameter(HTTPParameterMode = .path) var name: String"),
                    .string("@Parameter(HTTPParameterMode = .query) var greeting: String?")
                ]
            ))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/requestResponse2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("RequestResponse2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("RequestResponse2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("requestResponse"))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Hello, Philipp!")
        }
        
        container.reset()
        
        try Self.app.testable().test(.GET, "/requestResponse2/Paul?greeting=Hi") { response in
            let logMessage = container.messages[0]
            let metadata = try XCTUnwrap(logMessage.metadata)
            let requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["greeting"]), .string("Hi"))
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Paul"))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Hi, Paul!")
        }
        
        container.reset()
    }
    
    func testRequestResponsePattern3() throws {
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        try Self.app.testable().test(.GET, "/requestResponse3/Philipp") { response in
            XCTAssertEqual(1, container.messages.count)
            if container.messages.count != 1 {
                XCTFail("Log message count isn't correct")
            }
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world!")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file, #file)
            XCTAssertEqual(logMessage.function, "handle()")
            XCTAssertEqual(logMessage.line, Self.requestResponseHandler3Line)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(1, metadata.count)
            
            // Logger UUID metadata
            XCTAssertEqual(try XCTUnwrap(metadata["logger-uuid"]), .string(ApodiniLoggerTests.loggerUUID.uuidString))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Hello, Philipp!")
        }
        
        container.reset()
    }
    
    func testRequestResponsePattern4() throws {
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        try Self.app.testable().test(.GET, "/requestResponse4/Philipp") { response in
            XCTAssertEqual(1, container.messages.count)
            if container.messages.count != 1 {
                XCTFail("Log message count isn't correct")
            }
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world!")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file, #file)
            XCTAssertEqual(logMessage.function, "handle()")
            XCTAssertEqual(logMessage.line, Self.requestResponseHandler4Line)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(2, metadata.count)
            
            // Logger UUID metadata
            XCTAssertNotNil(try XCTUnwrap(metadata["logger-uuid"]))
            
            // Endpoint metadata
            let endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(8, endpointMetadata.count)
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array(
                [
                    .string("@Parameter(HTTPParameterMode = .path) var name: String"),
                    .string("@Parameter(HTTPParameterMode = .query) var greeting: String?")
                ]
            ))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/requestResponse4"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("RequestResponse4"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("RequestResponse4"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("requestResponse"))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Hello, Philipp!")
        }
        
        container.reset()
    }
    
    func testRequestResponsePattern5() throws {
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        let complexParameter = ComplexParameter(
            string: "test",
            int: 1,
            double: 1.2,
            bool: true,
            array: ["test2"],
            dictionary: [
                1: "test3",
                2: "test4"
            ]
        )
        
        let body = try JSONEncoder().encodeAsByteBuffer(complexParameter, allocator: .init())
        
        try Self.app.testable().test(.GET, "/requestResponse5", body: body) { response in
            XCTAssertEqual(1, container.messages.count)
            if container.messages.count != 1 {
                XCTFail("Log message count isn't correct")
            }
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world!")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file, #file)
            XCTAssertEqual(logMessage.function, "handle()")
            XCTAssertEqual(logMessage.line, Self.requestResponseHandler5Line)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(2, metadata.count)
            
            // Logger UUID metadata
            XCTAssertNotNil(try XCTUnwrap(metadata["logger-uuid"]))
            
            // Request metdata
            let requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(10, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /requestResponse5"))
            
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            let parameter = try XCTUnwrap(parameterRequestMetadata["complexParameter"]?.metadataDictionary)
            XCTAssertEqual(parameter.count, 6)
            let dictionary = try XCTUnwrap(parameter["dictionary"]?.metadataDictionary)
            XCTAssertEqual(dictionary.count, 2)
            XCTAssertEqual(try XCTUnwrap(dictionary["1"]), .string("test3"))
            XCTAssertEqual(try XCTUnwrap(dictionary["2"]), .string("test4"))
            let array = try XCTUnwrap(parameter["array"]?.metadataArray)
            XCTAssertEqual(1, array.count)
            let firstArrayElement = try XCTUnwrap(array.first)
            XCTAssertEqual(firstArrayElement, .string("test2"))
            XCTAssertEqual(try XCTUnwrap(parameter["double"]), .string("1.2"))
            XCTAssertEqual(try XCTUnwrap(parameter["int"]), .string("1"))
            XCTAssertEqual(try XCTUnwrap(parameter["string"]), .string("test"))
            
            let bodyString = try XCTUnwrap(requestMetadata["HTTPBody"]?.metadataString)
            guard let bodyData = bodyString.data(using: .utf8) else {
                XCTFail("HTTP Body couldn't be checked")
                return
            }
            let complexParameter = try JSONDecoder().decode(ComplexParameter.self, from: bodyData)
            XCTAssertEqual(complexParameter, complexParameter)
            
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/requestResponse5>"))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Hi whats up?!")
        }
        
        container.reset()
    }
    
    func testServiceSideStreamingPattern() throws {
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        try Self.app.testable([.actualRequests]).test(
            version: .http1_1,
            .GET,
            "/serverSideStreaming?start=10",
            expectedBodyType: .stream
        ) { response in
            XCTAssertEqual(11, container.messages.count)
            // First message, begin of stream
            let firstLogMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(firstLogMessage.message, "Hello world - Countdown!")
            XCTAssertEqual(firstLogMessage.level, .info)
            XCTAssertEqual(firstLogMessage.file, #file)
            XCTAssertEqual(firstLogMessage.function, "handle()")
            XCTAssertEqual(firstLogMessage.line, Self.serverSideStreamingHandlerStreamingLine)

            // Assert metadata
            var metadata = try XCTUnwrap(firstLogMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            var exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array(
                [
                    .string("[lightweight]"),
                    .string("[content]"),
                    .string("[path]")
                ]
            ))
            
            // Request metdata
            var requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(10, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /serverSideStreaming"))
            var parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["start"]), .string("10"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://localhost/serverSideStreaming?start=10>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://localhost/serverSideStreaming?start=10>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://localhost/serverSideStreaming?start=10"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/serverSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/serverSideStreaming?start=10"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPBody"]), .string(""))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPContentType"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPVersion"]), .string("HTTP/1.1"))
            
            // Connection metadata
            var connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            var remoteAddress = try XCTUnwrap(connectionMetadata["remoteAddress"]?.metadataString)
            XCTAssertTrue(remoteAddress.contains("127.0.0.1"))
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("open"))     // The connection stays open
            XCTAssertNotNil(connectionMetadata["eventLoop"])
            
            // Logger UUID metadata
            XCTAssertNotNil(metadata["logger-uuid"])
            
            // Endpoint metadata
            var endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(8, endpointMetadata.count)
            var parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array(
                    [
                        .string("@Parameter(Mutability = .constant, HTTPParameterMode = .query) var start: Int = 10")
                    ]
                ) ||
                parameterEndpointMetadata == .array(
                    [
                        .string("@Parameter(HTTPParameterMode = .query, Mutability = .constant) var start: Int = 10")
                    ]
                )) {
                XCTFail("Endpoint Parameters not correct")
            }

            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/serverSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("ServerSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("Blob"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("ServerSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("serviceSideStream"))      // Server-side stream
            
            // Information metadata
            var informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
            XCTAssertEqual(1, informationMetadata.count)
                
            XCTAssertEqual(try XCTUnwrap(informationMetadata["host"]), .string("0.0.0.0"))
            
            // Last log message, End of stream
            let eleventhLogMessage = container.messages[10]
            
            // Assert log message, level etc.
            XCTAssertEqual(eleventhLogMessage.message, "Hello world - Launch!")
            XCTAssertEqual(eleventhLogMessage.level, .info)
            XCTAssertEqual(eleventhLogMessage.file, #file)
            XCTAssertEqual(eleventhLogMessage.function, "handle()")
            XCTAssertEqual(eleventhLogMessage.line, Self.serverSideStreamingHandlerFinalLine)

            // Assert metadata
            metadata = try XCTUnwrap(eleventhLogMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array(
                [
                    .string("[lightweight]"),
                    .string("[content]"),
                    .string("[path]")
                ]
            ))
            
            // Request metdata
            requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(10, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /serverSideStreaming"))
            parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["start"]), .string("10"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://localhost/serverSideStreaming?start=10>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://localhost/serverSideStreaming?start=10>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://localhost/serverSideStreaming?start=10"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/serverSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/serverSideStreaming?start=10"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPBody"]), .string(""))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPContentType"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPVersion"]), .string("HTTP/1.1"))
            
            // Connection metadata
            connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            remoteAddress = try XCTUnwrap(connectionMetadata["remoteAddress"]?.metadataString)
            XCTAssertTrue(remoteAddress.contains("127.0.0.1"))
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("end"))     // The connection is now closed
            XCTAssertNotNil(connectionMetadata["eventLoop"])
            
            // Logger UUID metadata
            XCTAssertNotNil(metadata["logger-uuid"])
            
            // Endpoint metadata
            endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(8, endpointMetadata.count)
            parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array(
                    [
                        .string("@Parameter(Mutability = .constant, HTTPParameterMode = .query) var start: Int = 10")
                    ]
                ) ||
                parameterEndpointMetadata == .array(
                    [
                        .string("@Parameter(HTTPParameterMode = .query, Mutability = .constant) var start: Int = 10")
                    ]
                )) {
                XCTFail("Endpoint Parameters not correct")
            }
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/serverSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("ServerSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("Blob"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("ServerSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("serviceSideStream"))      // Server-side stream
            
            // Information metadata
            informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
            XCTAssertEqual(1, informationMetadata.count)
                
            XCTAssertEqual(try XCTUnwrap(informationMetadata["host"]), .string("0.0.0.0"))
            
            XCTAssertEqual(response.status, .ok)
            let responseStream = try XCTUnwrap(response.bodyStorage.stream)
            XCTAssert(responseStream.isClosed)
            // We want to get rid of leading and trailing newlines since that would mess up the line splitting
            let responseText = try XCTUnwrap(response.bodyStorage.getFullBodyDataAsString()).trimmingLeadingAndTrailingWhitespace()
            XCTAssertEqual(responseText.split(separator: "\n"), [
                "10...",
                "9...",
                "8...",
                "7...",
                "6...",
                "5...",
                "4...",
                "3...",
                "2...",
                "1...",
                "🚀🚀🚀 Launch !!! 🚀🚀🚀"
            ])
        }
    }
    
    func testClientSideStreamingPattern() throws {
        let body = [
            [
                "query": [
                    "country": "Germany"
                ]
            ],
            [
                "query": [
                    "country": "Taiwan"
                ]
            ],
            [String: [String: String]]()
        ]
        
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        try Self.app.testable().test(
            .GET,
            "/clientSideStreaming",
            body: JSONEncoder().encodeAsByteBuffer(body, allocator: .init())
        ) { response in
            XCTAssertEqual(4, container.messages.count)
            // First log messsage
            var logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world - Streaming!")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file, #file)
            XCTAssertEqual(logMessage.function, "handle()")
            XCTAssertEqual(logMessage.line, Self.clientSideStreamingHandlerStreamingLine)

            // Assert metadata
            var metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            var exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array(
                [
                    .string("[lightweight]"),
                    .string("[content]"),
                    .string("[path]")
                ]
            ))
            
            // Request metdata
            var requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(10, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /clientSideStreaming"))
            var parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("Germany"))      // First data set
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/clientSideStreaming>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/clientSideStreaming>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://127.0.0.1:8000/clientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/clientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/clientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPBody"]), .string("""
            [\
            {"query":{"country":"Germany"}},\
            {"query":{"country":"Taiwan"}},\
            {}\
            ]
            """))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPContentType"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPVersion"]), .string("HTTP/1.1"))
            
            // Connection metadata
            var connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["remoteAddress"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("open"))    // Open connection state
            XCTAssertNotNil(connectionMetadata["eventLoop"])
            
            // Logger UUID metadata
            XCTAssertNotNil(metadata["logger-uuid"])
            
            // Endpoint metadata
            var endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(8, endpointMetadata.count)
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array(
                [
                    .string("@Parameter(HTTPParameterMode = .query) var country: String?")
                ]
            ))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/clientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("ClientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("ClientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("clientSideStream"))
            
            // Information metadata
            var informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
            XCTAssertEqual(0, informationMetadata.count)
            
            // Second log message
            logMessage = container.messages[1]
            XCTAssertEqual(logMessage.message, "Hello world - Streaming!")
            
            // Assert metadata
            metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Request metdata
            requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("Taiwan"))     // Another country
            
            // Connection metadata
            connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("open"))         // Open connection state
            
            // Third log message
            logMessage = container.messages[2]
            XCTAssertEqual(logMessage.message, "Hello world - Streaming!")
            
            // Assert metadata
            metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Request metdata
            requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("nil"))      // Empty country
            
            // Connection metadata
            connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("open"))         // Open connection state
            
            // Forth log message
            logMessage = container.messages[3]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world - End!")

            // Assert metadata
            metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array(
                [
                    .string("[lightweight]"),
                    .string("[content]"),
                    .string("[path]")
                ]
            ))
            
            // Request metdata
            requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(10, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /clientSideStreaming"))
            parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("nil"))     // No more data
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/clientSideStreaming>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/clientSideStreaming>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://127.0.0.1:8000/clientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/clientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/clientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPBody"]), .string("""
            [\
            {"query":{"country":"Germany"}},\
            {"query":{"country":"Taiwan"}},\
            {}\
            ]
            """))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPContentType"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPVersion"]), .string("HTTP/1.1"))
            
            // Connection metadata
            connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["remoteAddress"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("end"))      // End connection state
            XCTAssertNotNil(connectionMetadata["eventLoop"])
            
            // Logger UUID metadata
            XCTAssertNotNil(metadata["logger-uuid"])
            
            // Endpoint metadata
            endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(8, endpointMetadata.count)
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array(
                [
                    .string("@Parameter(HTTPParameterMode = .query) var country: String?")
                ]
            ))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/clientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("ClientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("ClientSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("clientSideStream"))
            
            // Information metadata
            informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
            XCTAssertEqual(0, informationMetadata.count)
 
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(
                try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()),
                "Hello, Germany, Taiwan and the World!"
            )
        }
        
        container.reset()
    }
    
    func testBidirectionalStreamingPattern() throws {
        let body = [
            [
                "query": [
                    "country": "Germany"
                ]
            ],
            [
                "query": [
                    "country": "Taiwan"
                ]
            ],
            [String: [String: String]]()
        ]
        
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        try Self.app.testable().test(.GET, "/bidirectionalStreaming", body: JSONEncoder().encodeAsByteBuffer(body, allocator: .init())) { response in
            XCTAssertEqual(4, container.messages.count)
            // First log messsage
            var logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world - Streaming!")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file, #file)
            XCTAssertEqual(logMessage.function, "handle()")
            XCTAssertEqual(logMessage.line, Self.bidirectionalStreamingHandlerStreamingLine)

            // Assert metadata
            var metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            var exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array(
                [
                    .string("[lightweight]"),
                    .string("[content]"),
                    .string("[path]")
                ]
            ))
            
            // Request metdata
            var requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(10, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /bidirectionalStreaming"))
            var parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("Germany"))      // First data set
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/bidirectionalStreaming>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/bidirectionalStreaming>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://127.0.0.1:8000/bidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/bidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/bidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPBody"]), .string("""
            [\
            {"query":{"country":"Germany"}},\
            {"query":{"country":"Taiwan"}},\
            {}\
            ]
            """))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPContentType"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPVersion"]), .string("HTTP/1.1"))
            
            // Connection metadata
            var connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["remoteAddress"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("open"))    // Open connection state
            XCTAssertNotNil(connectionMetadata["eventLoop"])
            
            // Logger UUID metadata
            XCTAssertNotNil(metadata["logger-uuid"])
            
            // Endpoint metadata
            var endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(8, endpointMetadata.count)
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array(
                [
                    .string("@Parameter(HTTPParameterMode = .query) var country: String?")
                ]
            ))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/bidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("BidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("BidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("bidirectionalStream"))
            
            // Information metadata
            var informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
            XCTAssertEqual(0, informationMetadata.count)
            
            // Second log message
            logMessage = container.messages[1]
            XCTAssertEqual(logMessage.message, "Hello world - Streaming!")
            
            // Assert metadata
            metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Request metdata
            requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("Taiwan"))     // Another country
            
            // Connection metadata
            connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("open"))         // Open connection state
            
            // Third log message
            logMessage = container.messages[2]
            XCTAssertEqual(logMessage.message, "Hello world - Streaming!")
            
            // Assert metadata
            metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Request metdata
            requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("nil"))      // Empty country
            
            // Connection metadata
            connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("open"))         // Open connection state
            
            // Forth log message
            logMessage = container.messages[3]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world - End!")

            // Assert metadata
            metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array(
                [
                    .string("[lightweight]"),
                    .string("[content]"),
                    .string("[path]")
                ]
            ))
            
            // Request metdata
            requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(10, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /bidirectionalStreaming"))
            parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("nil"))     // No more data
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/bidirectionalStreaming>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/bidirectionalStreaming>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://127.0.0.1:8000/bidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/bidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/bidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPBody"]), .string("""
            [\
            {"query":{"country":"Germany"}},\
            {"query":{"country":"Taiwan"}},\
            {}\
            ]
            """))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPContentType"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPVersion"]), .string("HTTP/1.1"))
            
            // Connection metadata
            connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["remoteAddress"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("end"))      // End connection state
            XCTAssertNotNil(connectionMetadata["eventLoop"])
            
            // Logger UUID metadata
            XCTAssertNotNil(metadata["logger-uuid"])
            
            // Endpoint metadata
            endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(8, endpointMetadata.count)
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array(
                [
                    .string("@Parameter(HTTPParameterMode = .query) var country: String?")
                ]
            ))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/bidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("BidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("BidirectionalStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("bidirectionalStream"))
            
            // Information metadata
            informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
            XCTAssertEqual(0, informationMetadata.count)
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.readNewData(decodedAs: [String].self, using: JSONDecoder()), [
                "Hello, Germany!",
                "Hello, Taiwan!",
                "Hello, World!"
            ])
        }
    }
}

extension Logger.MetadataValue {
    var metadataDictionary: Logger.Metadata? {
        if case .dictionary(let dictionary) = self {
            return dictionary
        }
        
        return nil
    }
    
    var metadataArray: [Logger.Metadata.Value]? {   // swiftlint:disable:this discouraged_optional_collection
        if case .array(let array) = self {
            return array
        }
        
        return nil
    }
    
    var metadataString: String? {
        if case .string(let string) = self {
            return string
        }
        
        return nil
    }
}
