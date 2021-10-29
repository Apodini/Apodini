//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import XCTApodini
import XCTVapor
import ApodiniVaporSupport
import Vapor
import Metrics
import ApodiniObserve
import ApodiniHTTP
@testable import Apodini
@testable import MetricsTestUtils

// swiftlint:disable closure_body_length
class ApodiniMetricsTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    static var app: Apodini.Application!
    static let testMetricsFactory = TestMetrics()
    
    static let counterLabel = "test_counter"
    static let counterLabel2 = "test_counter2"
    static let gaugeLabel = "test_gauge"
    static let histrogramLabel = "test_histogram"
    static let recorderLabel = "test_recorder"
    static let timerLabel = "test_timer"
    // swiftlint:disable implicitly_unwrapped_optional
    static var counter1Dimensions: [(String, String)]!
    // swiftlint:disable implicitly_unwrapped_optional
    static var greeterDimensions: [(String, String)]!
    
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
    
    struct Greeter: Handler {
        @Parameter(.http(.path)) var name: String
        
        @ApodiniCounter(label: ApodiniMetricsTests.counterLabel, dimensions: [("test", "dimension")], metadataLevel: .all) var counter
        @ApodiniCounter(label: ApodiniMetricsTests.counterLabel2, metadataLevel: .none) var counter2
        @ApodiniGauge(label: ApodiniMetricsTests.gaugeLabel) var gauge
        @ApodiniHistogram(label: ApodiniMetricsTests.histrogramLabel) var histogram
        @ApodiniRecorder(label: ApodiniMetricsTests.recorderLabel) var recorder
        @ApodiniTimer(label: ApodiniMetricsTests.timerLabel, preferredDisplayUnit: .nanoseconds) var timer

        func handle() -> String {
            counter.increment()
            counter.increment(by: 3)
            counter2.increment(by: 99)
            gauge.record(2.56)
            histogram.record(3.1415)
            recorder.record(9.91)
            timer.record(.milliseconds(11))
            ApodiniMetricsTests.counter1Dimensions = counter.dimensions
            ApodiniMetricsTests.greeterDimensions = gauge.dimensions
            return "Hello, \(name)!"
        }
    }
    
    @ConfigurationBuilder
    static var configuration: Configuration {
        HTTP()
        MetricsConfiguration(handlerConfiguration: MetricPushHandlerConfiguration(factory: Self.testMetricsFactory),
                             systemMetricsConfiguration: .on(
                                configuration: .init(
                                    pollInterval: .seconds(10),
                                    // Without custom dataProvider, only Linux metrics are supported
                                    dataProvider: nil,
                                    labels: .init(
                                        prefix: "process_",
                                        virtualMemoryBytes: "virtual_memory_bytes",
                                        residentMemoryBytes: "resident_memory_bytes",
                                        startTimeSeconds: "start_time_seconds",
                                        cpuSecondsTotal: "cpu_seconds_total",
                                        maxFds: "max_fds",
                                        openFds: "open_fds"
                                    )
                                )
                            )
        )
    }

    @ComponentBuilder
    static var content: some Component {
        Group("greeter") {
            Greeter()
        }
    }
    
    func testApodiniMetricTypesWithTestHandler() throws {
        try Self.app.vapor.app.testable(method: .inMemory).test(.GET, "/greeter/Philipp", body: nil) { response in
            // Counter 1
            let counter = try Self.testMetricsFactory.expectCounter(Self.counterLabel, Self.counter1Dimensions)
            
            XCTAssertEqual(counter.label, Self.counterLabel)
            XCTAssertEqual(counter.lastValue, 3)
            
            let expectedDimensions = [
                ("endpoint", "Greeter"),
                ("endpoint_path", "/greeter"),
                ("exporter", "Exporter"),
                ("operation", "read"),
                ("communicational_pattern", "requestResponse"),
                ("service_type", "unary"),
                ("response_type", "String")
            ]
            
            XCTAssertEqual(expectedDimensions.count + 1, counter.dimensions.count)
            counter.dimensions.forEach { key, value in
                XCTAssertTrue((expectedDimensions + [("test", "dimension")]).contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            // Counter 2 without metadata
            let counter2 = try Self.testMetricsFactory.expectCounter(Self.counterLabel2, [])
            XCTAssertEqual(counter2.label, Self.counterLabel2)
            XCTAssertEqual(counter2.lastValue, 99)
            
            XCTAssertEqual(0, counter2.dimensions.count)

            // Gauge
            let gauge = try Self.testMetricsFactory.expectGauge(Self.gaugeLabel, Self.greeterDimensions)
            
            XCTAssertEqual(gauge.label, Self.gaugeLabel)
            XCTAssertEqual(gauge.lastValue, 2.56)
            
            XCTAssertEqual(expectedDimensions.count, gauge.dimensions.count)
            gauge.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            // Histogram
            let histogram = try Self.testMetricsFactory.expectRecorder(Self.histrogramLabel, Self.greeterDimensions)
            
            XCTAssertEqual(histogram.label, Self.histrogramLabel)
            XCTAssertEqual(histogram.lastValue, 3.1415)
            
            XCTAssertEqual(expectedDimensions.count, histogram.dimensions.count)
            histogram.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            // Recorder
            let recorder = try Self.testMetricsFactory.expectRecorder(Self.recorderLabel, Self.greeterDimensions)
            
            XCTAssertEqual(recorder.label, Self.recorderLabel)
            XCTAssertEqual(recorder.lastValue, 9.91)
            
            XCTAssertEqual(expectedDimensions.count, recorder.dimensions.count)
            recorder.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            // Timer
            let timer = try Self.testMetricsFactory.expectTimer(Self.timerLabel, Self.greeterDimensions)
            
            XCTAssertEqual(timer.label, Self.timerLabel)
            XCTAssertEqual(Int64(11000000), timer.lastValue)
            
            XCTAssertEqual(expectedDimensions.count, timer.dimensions.count)
            timer.dimensions.forEach { key, value in
                XCTAssertTrue(expectedDimensions.contains(where: { expKey, expValue in
                    key == expKey && value == expValue
                }))
            }
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.content.decode(String.self, using: JSONDecoder()), "Hello, Philipp!")
        }
    }
}
