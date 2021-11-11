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
import Logging
import Metrics
import ApodiniObserve
import ApodiniHTTP
@testable import Apodini
@testable import SwiftLogTesting
@testable import MetricsTestUtils

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
        
        let metricsConfig = MetricsConfiguration(
            handlerConfiguration: MetricPushHandlerConfiguration(factory: Self.testMetricsFactory),
            systemMetricsConfiguration: .default
        )
        
        app = ApodiniMetricsTests.configureMetrics(app, metricsConfiguration: metricsConfig)
        
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
    static var configuration: Configuration {
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
        let container = TestLogMessages.container(forLabel: "org.apodini.observe.Greeter1.Exporter")
        container.reset()
        
        try Self.app.testable().test(.GET, "/greeter/first/Philipp") { response in
            // Counter
            let counter = try Self.testMetricsFactory.expectCounter(Self.counterLabel, Self.greeterDimensions)
            
            XCTAssertEqual(counter.label, Self.counterLabel)
            XCTAssertEqual(counter.lastValue, 1)
            
            let expectedDimensions = [
                ("endpoint", "Greeter1"),
                ("endpoint_path", "/greeter/first"),
                ("exporter", "Exporter"),
                ("operation", "read"),
                ("communicational_pattern", "requestResponse"),
                ("service_type", "unary"),
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
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Incoming request for endpoint Greeter1 via Exporter")
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
            
            XCTAssertEqual(8, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /greeter/first/:name"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /greeter/first/Philipp HTTP/1.1\ncontent-length: 0\n"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/greeter/first/Philipp"))
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
            let parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array([.string("@Parameter(Optionality = .required, HTTPParameterMode = .path) var name: String")]) ||
                 parameterEndpointMetadata == .array([.string("@Parameter(HTTPParameterMode = .path, Optionality = .required) var name: String")])) {
                XCTFail("Endpoint Parameters not correct")
            }
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/greeter/first"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("Greeter1"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("Greeter1"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("requestResponse"))
            
            // Information metadata
            let informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
                       
            XCTAssertEqual(1, informationMetadata.count)
            XCTAssertEqual(try XCTUnwrap(informationMetadata["content-length"]), .string("0"))
            
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
        let container = TestLogMessages.container(forLabel: "org.apodini.observe.Greeter2.Exporter")
        container.reset()
        
        try Self.app.testable().test(.GET, "/greeter/second/Philipp") { response in
            // Counter
            let counter = try Self.testMetricsFactory.expectCounter(Self.counterLabel, Self.greeterDimensions)
            
            XCTAssertEqual(counter.label, Self.counterLabel)
            XCTAssertEqual(counter.lastValue, 1)
            
            let expectedDimensions = [
                ("endpoint", "Greeter2"),
                ("endpoint_path", "/greeter/second"),
                ("exporter", "Exporter"),
                ("operation", "read"),
                ("communicational_pattern", "requestResponse"),
                ("service_type", "unary"),
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
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Incoming request for endpoint Greeter2 via Exporter")
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
            
            XCTAssertEqual(8, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /greeter/second/:name"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /greeter/second/Philipp HTTP/1.1\ncontent-length: 0\n"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/greeter/second/Philipp"))
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
            let parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array([.string("@Parameter(Optionality = .required, HTTPParameterMode = .path) var name: String")]) ||
                 parameterEndpointMetadata == .array([.string("@Parameter(HTTPParameterMode = .path, Optionality = .required) var name: String")])) {
                XCTFail("Endpoint Parameters not correct")
            }
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/greeter/second"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("Greeter2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("Greeter2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("requestResponse"))
            
            // Information metadata
            let informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
                       
            XCTAssertEqual(1, informationMetadata.count)
            XCTAssertEqual(try XCTUnwrap(informationMetadata["content-length"]), .string("0"))
            
            // Cleanup
            Self.testMetricsFactory.destroyTimer(responseTimeTimer)
            Self.testMetricsFactory.destroyCounter(requestCounter)
            container.reset()
            
            XCTAssertEqual(response.status, .internalServerError)
        }
    }
    
    func testApodiniMetricsRecorder3() throws {
        // Automatically recorded log
        let container = TestLogMessages.container(forLabel: "org.apodini.observe.Greeter1.Exporter")
        container.reset()
        
        try Self.app.testable().test(.GET, "/greeter/third/Philipp") { response in
            // Counter
            let counter = try Self.testMetricsFactory.expectCounter(Self.counterLabel, Self.greeterDimensions)
            
            XCTAssertEqual(counter.label, Self.counterLabel)
            XCTAssertEqual(counter.lastValue, 1)
            
            let expectedDimensions = [
                ("endpoint", "Greeter1"),
                ("endpoint_path", "/greeter/third"),
                ("exporter", "Exporter"),
                ("operation", "read"),
                ("communicational_pattern", "requestResponse"),
                ("service_type", "unary"),
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
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Incoming request for endpoint Greeter1 via Exporter")
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
            
            XCTAssertEqual(8, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /greeter/third/:name"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /greeter/third/Philipp HTTP/1.1\ncontent-length: 0\n"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/greeter/third/Philipp"))
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
            let parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array([.string("@Parameter(Optionality = .required, HTTPParameterMode = .path) var name: String")]) ||
                 parameterEndpointMetadata == .array([.string("@Parameter(HTTPParameterMode = .path, Optionality = .required) var name: String")])) {
                XCTFail("Endpoint Parameters not correct")
            }
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/greeter/third"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("Greeter1"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("Greeter1"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("requestResponse"))
            
            // Information metadata
            let informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
                       
            XCTAssertEqual(1, informationMetadata.count)
            XCTAssertEqual(try XCTUnwrap(informationMetadata["content-length"]), .string("0"))
            
            // Cleanup
            container.reset()
            
            XCTAssertEqual(response.status, .internalServerError)
        }
    }
    
    func testApodiniMetricsRecorder4() throws {
        // Automatically recorded log
        let container = TestLogMessages.container(forLabel: "org.apodini.observe.Greeter2.Exporter")
        container.reset()
        
        try Self.app.testable().test(.GET, "/greeter/forth/Philipp") { response in
            // Counter
            let counter = try Self.testMetricsFactory.expectCounter(Self.counterLabel, Self.greeterDimensions)
            
            XCTAssertEqual(counter.label, Self.counterLabel)
            XCTAssertEqual(counter.lastValue, 1)
            
            let expectedDimensions = [
                ("endpoint", "Greeter2"),
                ("endpoint_path", "/greeter/forth"),
                ("exporter", "Exporter"),
                ("operation", "read"),
                ("communicational_pattern", "requestResponse"),
                ("service_type", "unary"),
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
            let logMessage = container.messages[0]
            
            // Assert log message, level etc.
            XCTAssertEqual(logMessage.message, "Incoming request for endpoint Greeter2 via Exporter")
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
            
            XCTAssertEqual(8, requestMetadata.count)
            XCTAssertEqual(try XCTUnwrap(requestMetadata["route"]), .string("GET /greeter/forth/:name"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["hasSession"]), .string("false"))
            let parameterRequestMetadata = try XCTUnwrap(requestMetadata["parameters"]?.metadataDictionary)
            XCTAssertEqual(try XCTUnwrap(parameterRequestMetadata["name"]), .string("Philipp"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["description"]), .string("GET /greeter/forth/Philipp HTTP/1.1\ncontent-length: 0\n"))
            XCTAssertEqual(try XCTUnwrap(requestMetadata["url"]), .string("/greeter/forth/Philipp"))
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
            let parameterEndpointMetadata = try XCTUnwrap(endpointMetadata["parameters"])
            if !(parameterEndpointMetadata == .array([.string("@Parameter(Optionality = .required, HTTPParameterMode = .path) var name: String")]) ||
                 parameterEndpointMetadata == .array([.string("@Parameter(HTTPParameterMode = .path, Optionality = .required) var name: String")])) {
                XCTFail("Endpoint Parameters not correct")
            }
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["operation"]), .string("read"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["endpointPath"]), .string("/greeter/forth"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerType"]), .string("Greeter2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["serviceType"]), .string("unary"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["handlerReturnType"]), .string("String"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["version"]), .string("unknown"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["name"]), .string("Greeter2"))
            XCTAssertEqual(try XCTUnwrap(endpointMetadata["communicationalPattern"]), .string("requestResponse"))
            
            // Information metadata
            let informationMetadata = try XCTUnwrap(metadata["information"]?.metadataDictionary)
                       
            XCTAssertEqual(1, informationMetadata.count)
            XCTAssertEqual(try XCTUnwrap(informationMetadata["content-length"]), .string("0"))
            
            // Cleanup
            Self.testMetricsFactory.destroyCounter(errorRateCounter)
            container.reset()
            
            XCTAssertEqual(response.status, .internalServerError)
        }
    }
}
