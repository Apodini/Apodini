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
import XCTApodiniObserve
import Logging
import Metrics
import ApodiniObserve
import ApodiniHTTP
@testable import Apodini
@testable import SwiftLogTesting
@testable import MetricsTestUtils
import XCTUtils

// swiftlint:disable closure_body_length
class ApodiniMetricsRecorderTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    static var app: Apodini.Application!
    static let testMetricsFactory = TestMetrics()
    
    static let counterLabel = "test_counter"
    // swiftlint:disable implicitly_unwrapped_optional
    static var greeterDimensions: [(String, String)]!
    
    override class func setUp() {
        super.setUp()
        
        app = Application()
        configuration.configure(app)
        
        let loggingConfig = LoggerConfiguration(
            logHandlers: TestingLogHandler.init,
            logLevel: .info
        )
        
        let metricsConfig = MetricsConfiguration(
            handlerConfiguration: MetricPushHandlerConfiguration(factory: Self.testMetricsFactory),
            systemMetricsConfiguration: .default
        )
        
        app = ApodiniLoggerTests.configureLogger(app, loggerConfiguration: loggingConfig)
        app = XCTApodiniObserve.configureMetrics(app, metricsConfiguration: metricsConfig)
        
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        content.accept(visitor)
        visitor.finishParsing()
    }
    
    override class func tearDown() {
        super.tearDown()
        
        app.shutdown()
        
        XCTAssertApodiniApplicationNotRunning()
    }
    
    struct Greeter1: Handler {
        @Parameter(.http(.path)) var name: String
        
        @ApodiniCounter(label: ApodiniMetricsRecorderTests.counterLabel) var counter
        
        @Throws(.serverError, reason: "some error occured") var error

        func handle() throws -> String {
            counter.increment()
            ApodiniMetricsRecorderTests.greeterDimensions = counter.dimensions
            if name == "Philipp" {
                throw error
            }
            return "Hello, \(name)!"
        }
    }
    
    struct Greeter2: Handler {
        @Parameter(.http(.path)) var name: String
        
        @ApodiniCounter(label: ApodiniMetricsRecorderTests.counterLabel) var counter
        
        @Throws(.serverError, reason: "some error occured") var error

        func handle() throws -> String {
            counter.increment()
            ApodiniMetricsRecorderTests.greeterDimensions = counter.dimensions
            if name == "Philipp" {
                throw error
            }
            return "Hello, \(name)!"
        }
    }
    
    @ConfigurationBuilder
    static var configuration: any Configuration {
        HTTP()
    }

    @ComponentBuilder
    static var content: some Component {
        Group("greeter") {
            Group("first") {
                Greeter1()
                    .record(.all)
            }
            Group("second") {
                Greeter2()
            }.record(.responseTime + .requestCounter)
            Group("third") {
                Greeter1()
                    .record(ExampleRecorder())
            }
            Group("forth") {
                Greeter2()
            }.record(ExampleRecorder() + .errorRate)
        }
    }
    
    struct ExampleRecorder: MetricsRecorder {
        var before: [RecordingClosures<String, String>.Before]
        var after: [RecordingClosures<String, String>.After]
        var afterException: [RecordingClosures<String, String>.AfterException]
        
        init(before: [RecordingClosures<String, String>.Before] = [],
             after: [RecordingClosures<String, String>.After] = [],
             afterException: [RecordingClosures<String, String>.AfterException] = []) {
            self.before = before
            self.after = after
            self.afterException = afterException
        }
    }
    
    func testApodiniMetricsRecorder1() throws {
        // Automatically recorded log
        let container = TestLogMessages.container(forLabel: "org.apodini.observe.Greeter1.HTTPInterfaceExporter")
        container.reset()
        
        try Self.app.testable().test(.GET, "/greeter/first/Philipp") { response in
            // Counter
            let counter = try Self.testMetricsFactory.expectCounter(Self.counterLabel, Self.greeterDimensions)
            
            XCTAssertEqual(counter.label, Self.counterLabel)
            XCTAssertEqual(counter.lastValue, 1)
            
            let expectedDimensions = [
                ("endpoint", "Greeter1"),
                ("endpoint_path", "/greeter/first"),
                ("exporter", "HTTPInterfaceExporter"),
                ("operation", "read"),
                ("communication_pattern", "requestResponse"),
                ("response_type", "String")
            ]
            
            let expectedErrorDimensions = expectedDimensions + [
                ("error_type", "ApodiniError"),
                ("error_description", "some error occured")
            ]
            
            XCTAssertEqual(expectedDimensions.count, counter.dimensions.count)
            counter.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            // Automatically recorded metrics
            let responseTimeTimer = try Self.testMetricsFactory.expectTimer("response_time_nanoseconds", Self.greeterDimensions)
            let requestCounter = try Self.testMetricsFactory.expectCounter("request_counter", Self.greeterDimensions)
            let errorRateCounter = try Self.testMetricsFactory.expectCounter("error_counter", Self.greeterDimensions +
                 [
                     ("error_type", "ApodiniError"),
                     ("error_description", "some error occured")
                 ]
            )
            
            XCTAssertEqual(responseTimeTimer.label, "response_time_nanoseconds")
            let lastValue = try XCTUnwrap(responseTimeTimer.lastValue)
            XCTAssertGreaterThan(lastValue, 1)
            responseTimeTimer.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            XCTAssertEqual(requestCounter.label, "request_counter")
            XCTAssertEqual(requestCounter.lastValue, 1)
            requestCounter.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            XCTAssertEqual(errorRateCounter.label, "error_counter")
            XCTAssertEqual(errorRateCounter.lastValue, 1)
            errorRateCounter.dimensions.forEach { key, value in
                XCTAssertTrue(expectedErrorDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            XCTAssertEqual(1, container.messages.count)
            let logMessage = try XCTUnwrap(container.messages.first)
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Incoming request for endpoint Greeter1 via HTTPInterfaceExporter")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file.components(separatedBy: "/").last, "RecordingHandler.swift")
            XCTAssertEqual(logMessage.function, "handle()")
            XCTAssertEqual(logMessage.line, 63)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            let exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("HTTPInterfaceExporter"))
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
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /greeter/first/:name"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/greeter/first/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/greeter/first/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://127.0.0.1:8000/greeter/first/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/greeter/first/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/greeter/first/Philipp"))
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
            let parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array([.string("@Parameter(Optionality = .required, HTTPParameterMode = .path) var name: String")]) ||
                 parameterEndpointMetadata == .array([.string("@Parameter(HTTPParameterMode = .path, Optionality = .required) var name: String")])) {
                XCTFail("Endpoint Parameters not correct")
            }
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/greeter/first"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("Greeter1"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("Greeter1"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("requestResponse"))
            
            // Information metadata
            let informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
            XCTAssertEqual(0, informationMetadata.count)
            
            // Cleanup
            Self.testMetricsFactory.destroyTimer(responseTimeTimer)
            Self.testMetricsFactory.destroyCounter(requestCounter)
            Self.testMetricsFactory.destroyCounter(errorRateCounter)
            container.reset()
            
            XCTAssertEqual(response.status, .internalServerError)
        }
    }
    
    func testApodiniMetricsRecorder2() throws {
        // Automatically recorded log
        let container = TestLogMessages.container(forLabel: "org.apodini.observe.Greeter2.HTTPInterfaceExporter")
        container.reset()
        
        try Self.app.testable().test(.GET, "/greeter/second/Philipp") { response in
            // Counter
            let counter = try Self.testMetricsFactory.expectCounter(Self.counterLabel, Self.greeterDimensions)
            
            XCTAssertEqual(counter.label, Self.counterLabel)
            XCTAssertEqual(counter.lastValue, 1)
            
            let expectedDimensions = [
                ("endpoint", "Greeter2"),
                ("endpoint_path", "/greeter/second"),
                ("exporter", "HTTPInterfaceExporter"),
                ("operation", "read"),
                ("communication_pattern", "requestResponse"),
                ("response_type", "String")
            ]
            
            XCTAssertEqual(expectedDimensions.count, counter.dimensions.count)
            counter.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            // Automatically recorded metrics
            let responseTimeTimer = try Self.testMetricsFactory.expectTimer("response_time_nanoseconds", Self.greeterDimensions)
            let requestCounter = try Self.testMetricsFactory.expectCounter("request_counter", Self.greeterDimensions)
            XCTAssertThrowsError(try Self.testMetricsFactory.expectCounter("error_counter", Self.greeterDimensions +
                                                                                       [
                                                                                           ("error_type", "ApodiniError"),
                                                                                           ("error_description", "some error occured")
                                                                                       ]
                                                                                  ))
            
            XCTAssertEqual(responseTimeTimer.label, "response_time_nanoseconds")
            let lastValue = try XCTUnwrap(responseTimeTimer.lastValue)
            XCTAssertGreaterThan(lastValue, 1)
            responseTimeTimer.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            XCTAssertEqual(requestCounter.label, "request_counter")
            XCTAssertEqual(requestCounter.lastValue, 1)
            requestCounter.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            XCTAssertEqual(1, container.messages.count)
            let logMessage = try XCTUnwrap(container.messages.first)
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Incoming request for endpoint Greeter2 via HTTPInterfaceExporter")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file.components(separatedBy: "/").last, "RecordingHandler.swift")
            XCTAssertEqual(logMessage.function, "handle()")
            XCTAssertEqual(logMessage.line, 63)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            let exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("HTTPInterfaceExporter"))
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
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /greeter/second/:name"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/greeter/second/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/greeter/second/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://127.0.0.1:8000/greeter/second/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/greeter/second/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/greeter/second/Philipp"))
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
            let parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array([.string("@Parameter(Optionality = .required, HTTPParameterMode = .path) var name: String")]) ||
                 parameterEndpointMetadata == .array([.string("@Parameter(HTTPParameterMode = .path, Optionality = .required) var name: String")])) {
                XCTFail("Endpoint Parameters not correct")
            }
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/greeter/second"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("Greeter2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("Greeter2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("requestResponse"))
            
            // Information metadata
            let informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
            XCTAssertEqual(0, informationMetadata.count)
            
            // Cleanup
            Self.testMetricsFactory.destroyTimer(responseTimeTimer)
            Self.testMetricsFactory.destroyCounter(requestCounter)
            container.reset()
            
            XCTAssertEqual(response.status, .internalServerError)
        }
    }
    
    func testApodiniMetricsRecorder3() throws {
        // Automatically recorded log
        let container = TestLogMessages.container(forLabel: "org.apodini.observe.Greeter1.HTTPInterfaceExporter")
        container.reset()
        
        try Self.app.testable().test(.GET, "/greeter/third/Philipp") { response in
            // Counter
            let counter = try Self.testMetricsFactory.expectCounter(Self.counterLabel, Self.greeterDimensions)
            
            XCTAssertEqual(counter.label, Self.counterLabel)
            XCTAssertEqual(counter.lastValue, 1)
            
            let expectedDimensions = [
                ("endpoint", "Greeter1"),
                ("endpoint_path", "/greeter/third"),
                ("exporter", "HTTPInterfaceExporter"),
                ("operation", "read"),
                ("communication_pattern", "requestResponse"),
                ("response_type", "String")
            ]
            
            XCTAssertEqual(expectedDimensions.count, counter.dimensions.count)
            counter.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            // Automatically recorded metrics
            XCTAssertThrowsError(try Self.testMetricsFactory.expectTimer("response_time_nanoseconds", Self.greeterDimensions))
            XCTAssertThrowsError(try Self.testMetricsFactory.expectCounter("request_counter", Self.greeterDimensions))
            XCTAssertThrowsError(try Self.testMetricsFactory.expectCounter("error_counter", Self.greeterDimensions +
                                                                                       [
                                                                                           ("error_type", "ApodiniError"),
                                                                                           ("error_description", "some error occured")
                                                                                       ]
                                                                                  ))
            
            XCTAssertEqual(1, container.messages.count)
            let logMessage = try XCTUnwrap(container.messages.first)
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Incoming request for endpoint Greeter1 via HTTPInterfaceExporter")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file.components(separatedBy: "/").last, "RecordingHandler.swift")
            XCTAssertEqual(logMessage.function, "handle()")
            XCTAssertEqual(logMessage.line, 63)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            let exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("HTTPInterfaceExporter"))
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
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /greeter/third/:name"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/greeter/third/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/greeter/third/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://127.0.0.1:8000/greeter/third/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/greeter/third/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/greeter/third/Philipp"))
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
            let parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array([.string("@Parameter(Optionality = .required, HTTPParameterMode = .path) var name: String")]) ||
                 parameterEndpointMetadata == .array([.string("@Parameter(HTTPParameterMode = .path, Optionality = .required) var name: String")])) {
                XCTFail("Endpoint Parameters not correct")
            }
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/greeter/third"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("Greeter1"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("Greeter1"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("requestResponse"))
            
            // Information metadata
            let informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
            XCTAssertEqual(0, informationMetadata.count)
            
            // Cleanup
            container.reset()
            
            XCTAssertEqual(response.status, .internalServerError)
        }
    }
    
    func testApodiniMetricsRecorder4() throws {
        // Automatically recorded log
        let container = TestLogMessages.container(forLabel: "org.apodini.observe.Greeter2.HTTPInterfaceExporter")
        container.reset()
        
        try Self.app.testable().test(.GET, "/greeter/forth/Philipp") { response in
            // Counter
            let counter = try Self.testMetricsFactory.expectCounter(Self.counterLabel, Self.greeterDimensions)
            
            XCTAssertEqual(counter.label, Self.counterLabel)
            XCTAssertEqual(counter.lastValue, 1)
            
            let expectedDimensions = [
                ("endpoint", "Greeter2"),
                ("endpoint_path", "/greeter/forth"),
                ("exporter", "HTTPInterfaceExporter"),
                ("operation", "read"),
                ("communication_pattern", "requestResponse"),
                ("response_type", "String")
            ]
            
            let expectedErrorDimensions = expectedDimensions + [
                ("error_type", "ApodiniError"),
                ("error_description", "some error occured")
            ]
            
            XCTAssertEqual(expectedDimensions.count, counter.dimensions.count)
            counter.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            // Automatically recorded metrics
            XCTAssertThrowsError(try Self.testMetricsFactory.expectTimer("response_time_nanoseconds", Self.greeterDimensions))
            XCTAssertThrowsError(try Self.testMetricsFactory.expectCounter("request_counter", Self.greeterDimensions))
            let errorRateCounter = try Self.testMetricsFactory.expectCounter("error_counter", Self.greeterDimensions +
                 [
                     ("error_type", "ApodiniError"),
                     ("error_description", "some error occured")
                 ]
            )
            
            XCTAssertEqual(errorRateCounter.label, "error_counter")
            XCTAssertEqual(errorRateCounter.lastValue, 1)
            errorRateCounter.dimensions.forEach { key, value in
                XCTAssertTrue(expectedErrorDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            XCTAssertEqual(1, container.messages.count)
            let logMessage = try XCTUnwrap(container.messages.first)
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Incoming request for endpoint Greeter2 via HTTPInterfaceExporter")
            XCTAssertEqual(logMessage.level, .info)
            XCTAssertEqual(logMessage.file.components(separatedBy: "/").last, "RecordingHandler.swift")
            XCTAssertEqual(logMessage.function, "handle()")
            XCTAssertEqual(logMessage.line, 63)

            // Assert metadata
            let metadata = try XCTUnwrap(logMessage.metadata)
            XCTAssertEqual(6, metadata.count)
            
            // Exporter metadata
            let exporterMetadata = try XCTUnwrap(metadata["exporter"]?.metadataDictionary)
            
            XCTAssertEqual(2, exporterMetadata.count)
            XCTAssertEqual(try XCTUnwrap(exporterMetadata["type"]), .string("HTTPInterfaceExporter"))
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
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /greeter/forth/:name"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/greeter/forth/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["ApodiniNetworkingRequestDescription"]), .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/greeter/forth/Philipp>"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("http://127.0.0.1:8000/greeter/forth/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.path"]), .string("/greeter/forth/Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url.pathAndQuery"]), .string("/greeter/forth/Philipp"))
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
            let parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array([.string("@Parameter(Optionality = .required, HTTPParameterMode = .path) var name: String")]) ||
                 parameterEndpointMetadata == .array([.string("@Parameter(HTTPParameterMode = .path, Optionality = .required) var name: String")])) {
                XCTFail("Endpoint Parameters not correct")
            }
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/greeter/forth"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("Greeter2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("Greeter2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationPattern"]), .string("requestResponse"))
            
            // Information metadata
            let informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
            XCTAssertEqual(0, informationMetadata.count)
            
            // Cleanup
            Self.testMetricsFactory.destroyCounter(errorRateCounter)
            container.reset()
            
            XCTAssertEqual(response.status, .internalServerError)
        }
    }
}
