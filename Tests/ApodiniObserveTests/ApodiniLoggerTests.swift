//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import XCTApodini
import ApodiniVaporSupport
import Vapor
import ApodiniHTTP
@testable import Apodini
import XCTVapor
import Logging
@testable import SwiftLogTesting
@testable import ApodiniObserve

class ApodiniLoggerTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    static var app: Apodini.Application!
    
    static let loggingLabel = "logger.test"
    static let loggerUUID = UUID()
    static var firstRun = true
    
    override class func setUp() {
        super.setUp()
        
        app = Application()
        configuration.configure(app)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        content.accept(visitor)
        visitor.finishParsing()
    }
    
    override class func tearDown() {
        super.tearDown()
        
        app.shutdown()
        
        XCTAssertApodiniApplicationNotRunning()
    }
    
    struct RequestResponse: Handler {
        @Parameter(.http(.path)) var name: String
        
        @Parameter(.http(.query)) var greeting: String?
        
        @ApodiniLogger(label: ApodiniLoggerTests.loggingLabel) var logger

        func handle() -> String {
            logger.info("Hello world!")
            return "\(greeting ?? "Hello"), \(name)!"
        }
    }
    
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
            return "\(greeting ?? "Hello"), \(name)!"
        }
    }
    
    struct RequestResponse3: Handler {
        @Parameter(.http(.path)) var name: String
        
        @Parameter(.http(.query)) var greeting: String?
        
        @ApodiniLogger(id: ApodiniLoggerTests.loggerUUID,
                       label: ApodiniLoggerTests.loggingLabel,
                       metadataLevel: .none)
        var logger

        func handle() -> String {
            logger.info("Hello world!")
            return "\(greeting ?? "Hello"), \(name)!"
        }
    }
    
    struct RequestResponse4: Handler {
        @Parameter(.http(.path)) var name: String
        
        @Parameter(.http(.query)) var greeting: String?
        
        @ApodiniLogger(label: ApodiniLoggerTests.loggingLabel,
                       metadataLevel: .custom(metadata: ["endpoint"]))
        var logger

        func handle() -> String {
            logger.info("Hello world!")
            return "\(greeting ?? "Hello"), \(name)!"
        }
    }
    
    class FakeTimer: Apodini.ObservableObject {
        @Apodini.Published private var _trigger = true
        
        init() {  }
        
        func secondPassed() {
            _trigger.toggle()
        }
    }

    struct ServerSideStreaming: Handler {
        @Parameter(.http(.query), .mutability(.constant)) var start: Int = 10
        
        @State var counter = -1
        
        @ObservedObject var timer = FakeTimer()
        
        @ApodiniLogger(label: ApodiniLoggerTests.loggingLabel) var logger
        
        func handle() -> Apodini.Response<String> {
            timer.secondPassed()
            counter += 1
            
            if counter == start {
                logger.info("Hello world - Launch!")
                return .final("🚀🚀🚀 Launch !!! 🚀🚀🚀")
            } else {
                logger.info("Hello world - Countdown!")
                return .send("\(start - counter)...")
            }
        }
        
        
        var metadata: AnyHandlerMetadata {
            Pattern(.serviceSideStream)
        }
    }
    
    struct ClientSideStreaming: Handler {
        @Parameter(.http(.query)) var country: String?
        
        @Apodini.Environment(\.connection) var connection
        
        @State var list: [String] = []
        
        @ApodiniLogger(label: ApodiniLoggerTests.loggingLabel) var logger
        
        func handle() -> Apodini.Response<String> {
            if connection.state == .end {
                var response = "Hello, " + list[0..<list.count - 1].joined(separator: ", ")
                if let last = list.last {
                    response += " and " + last
                } else {
                    response += "everyone"
                }
                
                logger.info("Hello world - End!")
                
                return .final(response + "!")
            } else {
                list.append(country ?? "the World")
                
                logger.info("Hello world - Streaming!")
                
                return .nothing
            }
        }
        
        var metadata: AnyHandlerMetadata {
            Pattern(.clientSideStream)
        }
    }

    struct BidirectionalStreaming: Handler {
        @Parameter(.http(.query)) var country: String?
        
        @Apodini.Environment(\.connection) var connection
        
        @ApodiniLogger(label: ApodiniLoggerTests.loggingLabel) var logger
        
        func handle() -> Apodini.Response<String> {
            if connection.state == .end {
                logger.info("Hello world - End!")
                
                return .end
            } else {
                logger.info("Hello world - Streaming!")
                
                return .send("Hello, \(country ?? "World")!")
            }
        }
        
        var metadata: AnyHandlerMetadata {
            Pattern(.bidirectionalStream)
        }
    }

    @ConfigurationBuilder
    static var configuration: Configuration {
        HTTP()
        LoggerConfiguration(logHandlers: TestingLogHandler.init, logLevel: .info)
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
        
        try Self.app.vapor.app.testable(method: .inMemory).test(.GET, "/requestResponse/Philipp", body: nil) { response in
            XCTAssertEqual (1, container.messages.count)
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world!")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file, #file)
            XCTAssertEqual(logMessage.function, "handle()")
            //XCTAssertEqual(logMessage.line, 55)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            let exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array([.string("[lightweight]"), .string("[content]"), .string("[path]")]))
            
            // Request metdata
            let requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(8, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /requestResponse/:name"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["greeting"]), .string("null"))
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /requestResponse/Philipp HTTP/1.1\ncontent-length: 0\n"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/requestResponse/Philipp"))
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
            
            XCTAssertEqual(9, endpointMetadata.count)
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array([.string("@Parameter(HTTPParameterMode = .path) var name: String"),
                                                                                 .string("@Parameter(HTTPParameterMode = .query) var greeting: String?")]))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/requestResponse"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("RequestResponse"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("RequestResponse"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("requestResponse"))
            
            // Information metadata
            let informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
                       
            XCTAssertEqual(1, informationMetadata.count)
            XCTAssertEqual(try XCTUnwrap(informationMetadata["content-length"]), .string("0"))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hello, Philipp!")
        }
        
        container.reset()
        
        try Self.app.vapor.app.testable(method: .inMemory).test(.GET, "/requestResponse/Paul?greeting=Hi", body: nil) { response in
            let logMessage = container.messages[0]
            let metadata = try XCTUnwrap(logMessage.metadata)
            let requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["greeting"]), .string("Hi"))
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Paul"))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hi, Paul!")
        }
        
        container.reset()
    }
    
    func testRequestResponsePattern2() throws {
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        try Self.app.vapor.app.testable(method: .inMemory).test(.GET, "/requestResponse2/Philipp", body: nil) { response in
            XCTAssertEqual (1, container.messages.count)
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world!")
            XCTAssertEqual(logMessage.level, .debug)
            XCTAssertEqual(logMessage.file, #file)
            XCTAssertEqual(logMessage.function, "handle()")
            //XCTAssertEqual(logMessage.line, 73)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(4, metadata.count)
            
            // Exporter metadata
            let exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array([.string("[lightweight]"), .string("[content]"), .string("[path]")]))
            
            // Request metdata
            let requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(8, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /requestResponse2/:name"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["greeting"]), .string("null"))
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /requestResponse2/Philipp HTTP/1.1\ncontent-length: 0\n"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/requestResponse2/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPBody"]), .string(""))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPContentType"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPVersion"]), .string("HTTP/1.1"))
            
            // Logger UUID metadata
            XCTAssertNotNil(metadata["logger-uuid"])
            
            // Endpoint metadata
            let endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(9, endpointMetadata.count)
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array([.string("@Parameter(HTTPParameterMode = .path) var name: String"),
                                                                                 .string("@Parameter(HTTPParameterMode = .query) var greeting: String?")]))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/requestResponse2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("RequestResponse2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("RequestResponse2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("requestResponse"))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hello, Philipp!")
        }
        
        container.reset()
        
        try Self.app.vapor.app.testable(method: .inMemory).test(.GET, "/requestResponse2/Paul?greeting=Hi", body: nil) { response in
            let logMessage = container.messages[0]
            let metadata = try XCTUnwrap(logMessage.metadata)
            let requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["greeting"]), .string("Hi"))
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Paul"))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hi, Paul!")
        }
        
        container.reset()
    }
    
    func testRequestResponsePattern3() throws {
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        try Self.app.vapor.app.testable(method: .inMemory).test(.GET, "/requestResponse3/Philipp", body: nil) { response in
            XCTAssertEqual (1, container.messages.count)
            if container.messages.count != 1 {
                XCTFail()

            }
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world!")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file, #file)
            XCTAssertEqual(logMessage.function, "handle()")
            //XCTAssertEqual(logMessage.line, 88)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(1, metadata.count)
            
            // Logger UUID metadata
            XCTAssertEqual(try XCTUnwrap(metadata["logger-uuid"]), .string(ApodiniLoggerTests.loggerUUID.uuidString))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hello, Philipp!")
        }
        
        container.reset()
    }
    
    func testRequestResponsePattern4() throws {
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        try Self.app.vapor.app.testable(method: .inMemory).test(.GET, "/requestResponse4/Philipp", body: nil) { response in
            XCTAssertEqual (1, container.messages.count)
            if container.messages.count != 1 {
                XCTFail()
            }
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Hello world!")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file, #file)
            XCTAssertEqual(logMessage.function, "handle()")
            //XCTAssertEqual(logMessage.line, 88)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(2, metadata.count)
            
            // Logger UUID metadata
            XCTAssertNotNil(try XCTUnwrap(metadata["logger-uuid"]))
            
            // Endpoint metadata
            let endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(9, endpointMetadata.count)
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array([.string("@Parameter(HTTPParameterMode = .path) var name: String"),
                                                                                 .string("@Parameter(HTTPParameterMode = .query) var greeting: String?")]))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/requestResponse4"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("RequestResponse4"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("RequestResponse4"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("requestResponse"))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hello, Philipp!")
        }
        
        container.reset()
    }
    
    func testServiceSideStreamingPattern() throws {
        let container = TestLogMessages.container(forLabel: "org.apodini.observe." + ApodiniLoggerTests.loggingLabel)
        container.reset()
        
        try Self.app.vapor.app.testable(method: .inMemory).test(.GET, "/serverSideStreaming?start=10", body: nil) { response in
            XCTAssertEqual (11, container.messages.count)
            // First message, begin of stream
            let firstLogMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(firstLogMessage.message, "Hello world - Countdown!")
            XCTAssertEqual(firstLogMessage.level, .info)
            XCTAssertEqual(firstLogMessage.file, #file)
            XCTAssertEqual(firstLogMessage.function, "handle()")
            //XCTAssertEqual(logMessage.line, 55)

            // Assert metadata
            var metadata = try XCTUnwrap(firstLogMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            var exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array([.string("[lightweight]"), .string("[content]"), .string("[path]")]))
            
            // Request metdata
            var requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(8, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /serverSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
            var parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["start"]), .string("10"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /serverSideStreaming?start=10 HTTP/1.1\ncontent-length: 0\n"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/serverSideStreaming?start=10"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPBody"]), .string(""))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPContentType"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPVersion"]), .string("HTTP/1.1"))
            
            // Connection metadata
            var connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["remoteAddress"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("open"))     // The connection stays open
            XCTAssertNotNil(connectionMetadata["eventLoop"])
            
            // Logger UUID metadata
            XCTAssertNotNil(metadata["logger-uuid"])
            
            // Endpoint metadata
            var endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(9, endpointMetadata.count)
            var parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array([.string("@Parameter(Mutability = .constant, HTTPParameterMode = .query) var start: Int = 10")]) ||
                 parameterEndpointMetadata == .array([.string("@Parameter(HTTPParameterMode = .query, Mutability = .constant) var start: Int = 10")])) {
                XCTFail("Endpoint Parameters not correct")
            }

            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/serverSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("ServerSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("ServerSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("serviceSideStream"))      // Server-side stream
            
            // Information metadata
            var informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
                       
            XCTAssertEqual(1, informationMetadata.count)
            XCTAssertEqual(try XCTUnwrap(informationMetadata["content-length"]), .string("0"))
            
            // Last log message, End of stream
            let eleventhLogMessage = container.messages[10]
            
            // Assert log message, level etc.
            XCTAssertEqual(eleventhLogMessage.message, "Hello world - Launch!")
            XCTAssertEqual(eleventhLogMessage.level, .info)
            XCTAssertEqual(eleventhLogMessage.file, #file)
            XCTAssertEqual(eleventhLogMessage.function, "handle()")
            //XCTAssertEqual(logMessage.line, 55)

            // Assert metadata
            metadata = try XCTUnwrap(eleventhLogMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array([.string("[lightweight]"), .string("[content]"), .string("[path]")]))
            
            // Request metdata
            requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
            
            XCTAssertEqual(8, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /serverSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
            parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["start"]), .string("10"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /serverSideStreaming?start=10 HTTP/1.1\ncontent-length: 0\n"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/serverSideStreaming?start=10"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPBody"]), .string(""))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPContentType"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["HTTPVersion"]), .string("HTTP/1.1"))
            
            // Connection metadata
            connectionMetadata = try XCTUnwrap(metadata["connection"]?.metadataDictionary)
            
            XCTAssertEqual(3, connectionMetadata.count)
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["remoteAddress"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(connectionMetadata["state"]), .string("end"))     // The connection is now closed
            XCTAssertNotNil(connectionMetadata["eventLoop"])
            
            // Logger UUID metadata
            XCTAssertNotNil(metadata["logger-uuid"])
            
            // Endpoint metadata
            endpointMetadata = try XCTUnwrap(metadata["endpoint"]?.metadataDictionary)
            
            XCTAssertEqual(9, endpointMetadata.count)
            parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array([.string("@Parameter(Mutability = .constant, HTTPParameterMode = .query) var start: Int = 10")]) ||
                 parameterEndpointMetadata == .array([.string("@Parameter(HTTPParameterMode = .query, Mutability = .constant) var start: Int = 10")])) {
                XCTFail("Endpoint Parameters not correct")
            }
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/serverSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("ServerSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("ServerSideStreaming"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("serviceSideStream"))      // Server-side stream
            
            // Information metadata
            informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
                       
            XCTAssertEqual(1, informationMetadata.count)
            XCTAssertEqual(try XCTUnwrap(informationMetadata["content-length"]), .string("0"))
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.content.decode([String].self, using: JSONDecoder()), [
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
        
        try Self.app.vapor.app.testable(method: .inMemory)
            .test(.GET, "/clientSideStreaming", body: JSONEncoder().encodeAsByteBuffer(body, allocator: .init())) { response in
                XCTAssertEqual (4, container.messages.count)
                // First log messsage
                var logMessage = container.messages[0]
                
                // Assert log message, level etc.
                XCTAssertEqual(logMessage.message, "Hello world - Streaming!")
                XCTAssertEqual(logMessage.level, .info)
                XCTAssertEqual(logMessage.file, #file)
                XCTAssertEqual(logMessage.function, "handle()")
                //XCTAssertEqual(logMessage.line, 55)

                // Assert metadata
                var metadata = try XCTUnwrap(logMessage.metadata)
                XCTAssertEqual(6, metadata.count)
                
                // Exporter metadata
                var exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
                
                XCTAssertEqual(2, exporterMetadata.count)
                XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
                XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array([.string("[lightweight]"), .string("[content]"), .string("[path]")]))
                
                // Request metdata
                var requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
                
                XCTAssertEqual(8, requestMetadata.count)
                XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /clientSideStreaming"))
                XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
                var parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
                XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("Germany"))      // First data set
                XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /clientSideStreaming HTTP/1.1\ncontent-length: 67\n"))
                XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/clientSideStreaming"))
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
                
                XCTAssertEqual(9, endpointMetadata.count)
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array([.string("@Parameter(HTTPParameterMode = .query) var country: String?")]))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/clientSideStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("ClientSideStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("ClientSideStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("clientSideStream"))
                
                // Information metadata
                var informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
                           
                XCTAssertEqual(1, informationMetadata.count)
                XCTAssertEqual(try XCTUnwrap(informationMetadata["content-length"]), .string("67"))
                
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
                XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("null"))      // Empty country
                
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
                XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array([.string("[lightweight]"), .string("[content]"), .string("[path]")]))
                
                // Request metdata
                requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
                
                XCTAssertEqual(8, requestMetadata.count)
                XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /clientSideStreaming"))
                XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
                parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
                XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("null"))     // No more data
                XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /clientSideStreaming HTTP/1.1\ncontent-length: 67\n"))
                XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/clientSideStreaming"))
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
                
                XCTAssertEqual(9, endpointMetadata.count)
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array([.string("@Parameter(HTTPParameterMode = .query) var country: String?")]))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/clientSideStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("ClientSideStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("ClientSideStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("clientSideStream"))
                
                // Information metadata
                informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
                           
                XCTAssertEqual(1, informationMetadata.count)
                XCTAssertEqual(try XCTUnwrap(informationMetadata["content-length"]), .string("67"))
                
                XCTAssertEqual(response.status, .ok)
                XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hello, Germany, Taiwan and the World!")
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
        
        try Self.app.vapor.app.testable(method: .inMemory)
            .test(.GET, "/bidirectionalStreaming", body: JSONEncoder().encodeAsByteBuffer(body, allocator: .init())) { response in
                XCTAssertEqual (4, container.messages.count)
                // First log messsage
                var logMessage = container.messages[0]
                
                // Assert log message, level etc.
                XCTAssertEqual(logMessage.message, "Hello world - Streaming!")
                XCTAssertEqual(logMessage.level, .info)
                XCTAssertEqual(logMessage.file, #file)
                XCTAssertEqual(logMessage.function, "handle()")
                //XCTAssertEqual(logMessage.line, 55)

                // Assert metadata
                var metadata = try XCTUnwrap(logMessage.metadata)
                XCTAssertEqual(6, metadata.count)
                
                // Exporter metadata
                var exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
                
                XCTAssertEqual(2, exporterMetadata.count)
                XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("Exporter"))
                XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array([.string("[lightweight]"), .string("[content]"), .string("[path]")]))
                
                // Request metdata
                var requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
                
                XCTAssertEqual(8, requestMetadata.count)
                XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /bidirectionalStreaming"))
                XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
                var parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
                XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("Germany"))      // First data set
                XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /bidirectionalStreaming HTTP/1.1\ncontent-length: 67\n"))
                XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/bidirectionalStreaming"))
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
                
                XCTAssertEqual(9, endpointMetadata.count)
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array([.string("@Parameter(HTTPParameterMode = .query) var country: String?")]))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/bidirectionalStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("BidirectionalStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("BidirectionalStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("bidirectionalStream"))
                
                // Information metadata
                var informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
                           
                XCTAssertEqual(1, informationMetadata.count)
                XCTAssertEqual(try XCTUnwrap(informationMetadata["content-length"]), .string("67"))
                
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
                XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("null"))      // Empty country
                
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
                XCTAssertEqual(try XCTUnwrap(exporterMetadata["parameterNamespace"]), .array([.string("[lightweight]"), .string("[content]"), .string("[path]")]))
                
                // Request metdata
                requestMetadata = try XCTUnwrap(metadata["request"]?.metadataDictionary)
                
                XCTAssertEqual(8, requestMetadata.count)
                XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /bidirectionalStreaming"))
                XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
                parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
                XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["country"]), .string("null"))     // No more data
                XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /bidirectionalStreaming HTTP/1.1\ncontent-length: 67\n"))
                XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/bidirectionalStreaming"))
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
                
                XCTAssertEqual(9, endpointMetadata.count)
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["parameters"]), .array([.string("@Parameter(HTTPParameterMode = .query) var country: String?")]))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/bidirectionalStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("BidirectionalStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("BidirectionalStreaming"))
                XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("bidirectionalStream"))
                
                // Information metadata
                informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
                           
                XCTAssertEqual(1, informationMetadata.count)
                XCTAssertEqual(try XCTUnwrap(informationMetadata["content-length"]), .string("67"))
                
                XCTAssertEqual(response.status, .ok)
                XCTAssertEqual(try response.content.decode([String].self, using: JSONDecoder()), [
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
}
