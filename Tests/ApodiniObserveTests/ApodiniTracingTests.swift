//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniHTTP
import Tracing
import XCTApodini
import XCTApodiniObserve
import XCTest

@testable import Apodini
@testable import ApodiniObserve
@testable import Instrumentation

final class ApodiniTracingTests: XCTestCase {
    func testTracingConfiguration_withSimpleInstrument() {
        // Arrange
        let app = Application()

        let configuration = TracingConfiguration.testable(
            TracerConfiguration(NoOpTracer())
        )

        // Act
        configuration.configure(app)

        // Assert
        // Make sure the InstrumentationSystem is bootstrapped with a single NoOpTracer
        XCTAssertTrue(InstrumentationSystem.instrument is NoOpTracer)

        // Assert that the app's lifecycle doesn't include any InstrumentConfiguration.Lifecycle
        let tracerLifecycleHandlers = app.lifecycle.handlers.filter { $0 is TracerConfiguration.Lifecycle }
        XCTAssertTrue(tracerLifecycleHandlers.isEmpty)

        // Act
        app.shutdown()

        // Assert
        XCTAssertApodiniApplicationNotRunning()
    }

    func testTracingConfiguration_withInstrumentConfiguration() {
        // Arrange
        let app = Application()

        var tracerShutdownCallCount = 0
        let configuration = TracingConfiguration.testable(
            TracerConfiguration { _ in
                (NoOpTracer(), { tracerShutdownCallCount += 1 })
            }
        )

        // Act
        configuration.configure(app)

        // Assert
        // Make sure the InstrumentationSystem is bootstrapped with a single NoOpTracer
        XCTAssertTrue(InstrumentationSystem.instrument is NoOpTracer)

        // Assert that the app's lifecycle doesn't include any InstrumentConfiguration.Lifecycle
        let tracerLifecycleHandlers = app.lifecycle.handlers.filter { $0 is TracerConfiguration.Lifecycle }
        XCTAssertEqual(tracerLifecycleHandlers.count, 1)

        // Act
        app.shutdown()

        // Assert
        XCTAssertEqual(tracerShutdownCallCount, 1)
        XCTAssertApodiniApplicationNotRunning()
    }

    func testTracingConfiguration_withMultipleInstruments() throws {
        // Arrange
        let app = Application()

        let configuration = TracingConfiguration.testable(
            TracerConfiguration(NoOpTracer()),
            TracerConfiguration { _ in
                (MockTracer(), nil)
            }
        )

        // Act
        configuration.configure(app)

        // Assert
        // Make sure the InstrumentationSystem is bootstrapped with a MultiplexInstrument
        // with a NoOpTracer and a MockTracer
        let multiplexInstrument = try XCTUnwrap(InstrumentationSystem.instrument as? MultiplexInstrument)
        XCTAssertNotNil(multiplexInstrument.firstInstrument(where: { $0 is NoOpTracer }))
        XCTAssertNotNil(multiplexInstrument.firstInstrument(where: { $0 is MockTracer }))

        // Assert that the app's lifecycle doesn't include any InstrumentConfiguration.Lifecycle
        let tracerLifecycleHandlers = app.lifecycle.handlers.filter { $0 is TracerConfiguration.Lifecycle }
        XCTAssertTrue(tracerLifecycleHandlers.isEmpty)

        // Act
        app.shutdown()

        // Assert
        XCTAssertApodiniApplicationNotRunning()
    }

    static var sutSpan: Span?
    struct SUTHandler: Handler {
        @Environment(\.tracer) var tracer: Tracer

        func handle() -> String {
            let span = tracer.startSpan("SUTHandler.handle()", baggage: .topLevel)
            sutSpan = span
            defer { span.end() }

            return "Hello World!"
        }
    }

    func testTracerRecordsSpan() throws {
        // Arrange
        let app = Application()

        Self.sutSpan = nil

        @ConfigurationBuilder
        var configuration: Configuration {
            HTTP()
            TracingConfiguration.testable(
                TracerConfiguration(MockTracer())
            )
        }
        configuration.configure(app)

        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        Group { SUTHandler() }.accept(visitor)
        visitor.finishParsing()

        // Act
        try app.testable().test(.GET, "/") { response in
            // Assert
            XCTAssertEqual(response.status, .ok)

            let sutSpan = try XCTUnwrap(Self.sutSpan as? MockTracer.MockSpan)
            XCTAssertEqual(sutSpan.operationName, "SUTHandler.handle()")
            XCTAssertEqual(sutSpan.endCallCount, 1)

            // Act
            app.shutdown()

            // Assert
            XCTAssertApodiniApplicationNotRunning()
        }
    }
}
