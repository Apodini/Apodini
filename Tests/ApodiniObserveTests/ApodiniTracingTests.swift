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
    func testTracingConfiguration_withSimpleInstrument() throws {
        // Arrange
        let app = Application()

        let configuration = TracingConfiguration.testable(
            InstrumentConfiguration(NoOpTracer())
        )

        // Act
        configuration.configure(app)

        // Assert
        // Make sure the InstrumentationSystem is bootstrapped with a MultiplexInstrument
        // with a NoOpTracer
        let multiplexInstrument = try XCTUnwrap(InstrumentationSystem.instrument as? MultiplexInstrument)
        XCTAssertNotNil(multiplexInstrument.firstInstrument(where: { $0 is NoOpTracer }))

        // Assert that the app's lifecycle doesn't include any InstrumentConfiguration.Lifecycle
        let instrumentLifecycleHandlers = app.lifecycle.handlers.filter { $0 is InstrumentConfiguration.Lifecycle }
        XCTAssertTrue(instrumentLifecycleHandlers.isEmpty)

        // Act
        app.shutdown()

        // Assert
        XCTAssertApodiniApplicationNotRunning()
    }

    func testTracingConfiguration_withInstrumentConfiguration() throws {
        // Arrange
        let app = Application()

        var instrumentShutdownCallCount = 0
        let configuration = TracingConfiguration.testable(
            InstrumentConfiguration { _ in
                (NoOpTracer(), { instrumentShutdownCallCount += 1 })
            }
        )

        // Act
        configuration.configure(app)

        // Assert
        // Make sure the InstrumentationSystem is bootstrapped with a MultiplexInstrument
        // with a NoOpTracer
        let multiplexInstrument = try XCTUnwrap(InstrumentationSystem.instrument as? MultiplexInstrument)
        XCTAssertNotNil(multiplexInstrument.firstInstrument(where: { $0 is NoOpTracer }))

        // Assert that the app's lifecycle doesn't include any InstrumentConfiguration.Lifecycle
        let instrumentLifecycleHandlers = app.lifecycle.handlers.filter { $0 is InstrumentConfiguration.Lifecycle }
        XCTAssertEqual(instrumentLifecycleHandlers.count, 1)

        // Act
        app.shutdown()

        // Assert
        XCTAssertEqual(instrumentShutdownCallCount, 1)
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
                InstrumentConfiguration(MockTracer())
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
