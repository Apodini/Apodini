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
import Metrics
@testable import Prometheus
@testable import ApodiniObserve
import ApodiniObserveMetricsPrometheus
import ApodiniHTTP
@testable import Apodini
@testable import MetricsTestUtils

// swiftlint:disable closure_body_length
class ApodiniMetricsPrometheusTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    static var app: Apodini.Application!
    static var metricsConfiguration: MetricsConfiguration!
    
    static let counterLabel = "test_counter"
    static let gaugeLabel = "test_gauge"
    static let histrogramLabel = "test_histogram"
    static let recorderLabel = "test_recorder"
    static let timerLabel = "test_timer"
    static let summaryLabel = "test_summary"
    
    override class func setUp() {
        super.setUp()
        
        app = Application()
        configuration.configure(app)
        
        Self.metricsConfiguration = MetricsConfiguration(prometheusHandlerConfiguration: .defaultPrometheus, systemMetricsConfiguration: .default)
        Self.metricsConfiguration = MetricsConfiguration(
            prometheusHandlerConfiguration: .defaultPrometheusWithConfig(),
            systemMetricsConfiguration: .default
        )
        app = ApodiniMetricsTests.configureMetrics(app, metricsConfiguration: Self.metricsConfiguration)
        
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
        
        @ApodiniCounter(label: ApodiniMetricsPrometheusTests.counterLabel) var counter
        @ApodiniGauge(label: ApodiniMetricsPrometheusTests.gaugeLabel) var gauge
        @ApodiniHistogram(label: ApodiniMetricsPrometheusTests.histrogramLabel) var histogram
        @ApodiniRecorder(label: ApodiniMetricsPrometheusTests.recorderLabel) var recorder
        @ApodiniTimer(label: ApodiniMetricsPrometheusTests.timerLabel, preferredDisplayUnit: .nanoseconds) var timer

        func handle() -> String {
            counter.increment(by: 3)
            gauge.record(2.56)
            histogram.record(3.1415)
            recorder.record(9.91)
            timer.record(.milliseconds(11))
            return "Hello, \(name)!"
        }
    }
    
    struct Greeter2: Handler {
        @Parameter(.http(.path)) var name: String
        
        @ApodiniPrometheusCounter(label: ApodiniMetricsPrometheusTests.counterLabel) var counter
        @ApodiniPrometheusGauge(label: ApodiniMetricsPrometheusTests.gaugeLabel) var gauge
        @ApodiniPrometheusHistogram(label: ApodiniMetricsPrometheusTests.histrogramLabel) var histogram
        @ApodiniPrometheusSummary(label: ApodiniMetricsPrometheusTests.summaryLabel) var summary

        func handle() -> String {
            counter.inc(3)
            gauge.set(256)
            histogram.observe(31415)
            summary.recordNanoseconds(11000000)
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
            Greeter()
        }
        Group("greeter2") {
            Greeter2()
        }
    }
    
    func testApodiniMetricTypesWithPrometheusHandler() throws {
        try Self.app.testable().test(.GET, "/greeter/Philipp") { response in
            guard let prometheusFactory = Self.metricsConfiguration.metricHandlerConfigurations[0].factory as? PrometheusMetricsFactory else {
                XCTFail("Prometheus Factory couldn't be extracted")
                return
            }
            let prometheusClient = prometheusFactory.client
            guard let counter: PromCounter<Int64, DimensionLabels> =
                    prometheusClient.getMetricInstance(with: Self.counterLabel, andType: .counter) else {
                XCTFail("Prometheus Metric couldn't be fetched")
                return
            }
            
            XCTAssertEqual(counter.name, Self.counterLabel)
            XCTAssertEqual(counter._type, .counter)
            XCTAssertEqual(counter.metrics.first?.value, 3)

            // Gauge
            guard let gauge: PromGauge<Double, DimensionLabels> =
                    prometheusClient.getMetricInstance(with: Self.gaugeLabel, andType: .gauge) else {
                XCTFail("Prometheus Metric couldn't be fetched")
                return
            }
            
            XCTAssertEqual(gauge.name, Self.gaugeLabel)
            XCTAssertEqual(gauge._type, .gauge)
            // As the metric value is private we have to collect the string and then check the assertions
            let gaugeString = gauge.collect()
            XCTAssert(gaugeString.contains(Self.gaugeLabel))
            XCTAssert(gaugeString.contains("2.56"))
            
            // Histogram
            guard let histogram: PromHistogram<Double, DimensionHistogramLabels> =
                    prometheusClient.getMetricInstance(with: Self.histrogramLabel, andType: .histogram) else {
                XCTFail("Prometheus Metric couldn't be fetched")
                return
            }
            
            XCTAssertEqual(histogram.name, Self.histrogramLabel)
            XCTAssertEqual(histogram._type, .histogram)
            let histrogramString = histogram.collect()
            XCTAssert(histrogramString.contains(Self.histrogramLabel))
            XCTAssert(histrogramString.contains("3.1415"))
            
            // Recorder
            guard let recorder: PromHistogram<Double, DimensionHistogramLabels> =
                    prometheusClient.getMetricInstance(with: Self.recorderLabel, andType: .histogram) else {
                XCTFail("Prometheus Metric couldn't be fetched")
                return
            }
            
            XCTAssertEqual(recorder.name, Self.recorderLabel)
            XCTAssertEqual(recorder._type, .histogram)
            let recorderString = recorder.collect()
            XCTAssert(recorderString.contains(Self.recorderLabel))
            XCTAssert(recorderString.contains("9.91"))
            
            // Timer
            guard let timer: PromSummary<Int64, DimensionSummaryLabels> =
                    prometheusClient.getMetricInstance(with: Self.timerLabel, andType: .summary) else {
                XCTFail("Prometheus Metric couldn't be fetched")
                return
            }
            
            XCTAssertEqual(timer.name, Self.timerLabel)
            XCTAssertEqual(timer._type, .summary)
            let timerString = timer.collect()
            XCTAssert(timerString.contains(Self.timerLabel))
            XCTAssert(timerString.contains("11"))
            
            // Cleanup
            prometheusClient.removeMetric(counter)
            prometheusClient.removeMetric(gauge)
            prometheusClient.removeMetric(histogram)
            prometheusClient.removeMetric(recorder)
            prometheusClient.removeMetric(timer)
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Hello, Philipp!")
        }
    }
    
    func testApodiniPrometheusMetricTypesWithPrometheusHandler() throws {
        try Self.app.testable().test(.GET, "/greeter2/Philipp") { response in
            guard let prometheusFactory = Self.metricsConfiguration.metricHandlerConfigurations[0].factory as? PrometheusMetricsFactory else {
                XCTFail("Prometheus Factory couldn't be extracted")
                return
            }
            let prometheusClient = prometheusFactory.client
            guard let counter: PromCounter<Int64, DimensionLabels> =
                    prometheusClient.getMetricInstance(with: Self.counterLabel, andType: .counter) else {
                XCTFail("Prometheus Metric couldn't be fetched")
                return
            }
            
            XCTAssertEqual(counter.name, Self.counterLabel)
            XCTAssertEqual(counter._type, .counter)
            XCTAssertEqual(counter.value, 3)

            // Gauge
            guard let gauge: PromGauge<Int64, DimensionLabels> =
                    prometheusClient.getMetricInstance(with: Self.gaugeLabel, andType: .gauge) else {
                XCTFail("Prometheus Metric couldn't be fetched")
                return
            }
            
            XCTAssertEqual(gauge.name, Self.gaugeLabel)
            XCTAssertEqual(gauge._type, .gauge)
            // As the metric value is private we have to collect the string and then check the assertions
            let gaugeString = gauge.collect()
            XCTAssert(gaugeString.contains(Self.gaugeLabel))
            XCTAssert(gaugeString.contains("256"))
            
            // Histogram
            guard let histogram: PromHistogram<Int64, DimensionHistogramLabels> =
                    prometheusClient.getMetricInstance(with: Self.histrogramLabel, andType: .histogram) else {
                XCTFail("Prometheus Metric couldn't be fetched")
                return
            }
            
            XCTAssertEqual(histogram.name, Self.histrogramLabel)
            XCTAssertEqual(histogram._type, .histogram)
            let histrogramString = histogram.collect()
            XCTAssert(histrogramString.contains(Self.histrogramLabel))
            XCTAssert(histrogramString.contains("31415"))
            
            // Summary
            guard let summary: PromSummary<Int64, DimensionSummaryLabels> =
                    prometheusClient.getMetricInstance(with: Self.summaryLabel, andType: .summary) else {
                XCTFail("Prometheus Metric couldn't be fetched")
                return
            }
            
            XCTAssertEqual(summary.name, Self.summaryLabel)
            XCTAssertEqual(summary._type, .summary)
            let summaryString = summary.collect()
            XCTAssert(summaryString.contains(Self.summaryLabel))
            XCTAssert(summaryString.contains("11000000"))
            
            // Cleanup
            prometheusClient.removeMetric(counter)
            prometheusClient.removeMetric(gauge)
            prometheusClient.removeMetric(histogram)
            prometheusClient.removeMetric(summary)
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(try response.bodyStorage.getFullBodyData(decodedAs: String.self, using: JSONDecoder()), "Hello, Philipp!")
        }
    }
}
