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

// swiftlint:disable closure_body_length
final class TracingHandlerTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    private static var app: Application!
    // swiftlint:disable implicitly_unwrapped_optional
    private static var tracer: MockTracer!

    override class func setUp() {
        super.setUp()

        app = Application()
        tracer = MockTracer()

        HTTP()
            .configure(app)

        TracingConfiguration
            .testable(InstrumentConfiguration(tracer))
            .configure(app)

        let content = Group {
            Group("success") {
                SuccessHandler()
            }
            Group("failure") {
                FailureHandler()
            }
        }.trace()
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        content.accept(visitor)
        visitor.finishParsing()
    }

    override class func tearDown() {
        app.shutdown()

        XCTAssertApodiniApplicationNotRunning()

        super.tearDown()
    }

    override func setUp() {
        super.setUp()

        Self.tracer.reset()
    }

    struct SuccessHandler: Handler {
        func handle() -> String {
            "Hello, success!"
        }
    }

    struct FailureHandler: Handler {
        @Parameter
        var isUserError: Bool

        @Throws(.badInput, reason: "Bad Input")
        var userError

        @Throws(.serverError, reason: "Server Error")
        var serverError

        func handle() throws -> Never {
            if isUserError {
                throw userError
            }
            throw serverError
        }
    }

    func testSuccessHandler() throws {
        // Act
        try Self.app.testable().test(.GET, "/success") { response in
            // Assert
            XCTAssertEqual(Self.tracer.extractCallCount, 1)

            XCTAssertEqual(Self.tracer.spans.count, 1)
            let span = try XCTUnwrap(Self.tracer.spans.first)
            XCTAssertEqual(span.operationName, "read SuccessHandler")
            XCTAssertEqual(span.kind, .server)

            XCTAssertEqual(span.attributes.count, 5)
            XCTAssertEqual(span.attributes.apodini.endpointName, "SuccessHandler")
            XCTAssertEqual(span.attributes.apodini.endpointOperation, "read")
            XCTAssertEqual(span.attributes.apodini.endpointPath, "/success")
            XCTAssertEqual(span.attributes.apodini.endpointCommunicationalPattern, "requestResponse")
            XCTAssertEqual(span.attributes.apodini.endpointVersion, "unknown")

            XCTAssertEqual(span.recordErrorCallCount, 0)
            XCTAssertEqual(span.setStatusCallCount, 0)

            XCTAssertEqual(span.endCallCount, 1)

            XCTAssertEqual(response.status, .ok)
        }
    }

    func testFailureHandler_whenUserError() throws {
        // Arrange
        var errorValue: Error?
        var statusValue: SpanStatus?
        Self.tracer.startSpanHandler = { span in
            span.recordErrorHandler = { error in
                errorValue = error
            }
            span.setStatusHandler = { status in
                statusValue = status
            }
        }

        // Act
        try Self.app.testable().test(.GET, "/failure?isUserError=1") { response in
            // Assert
            XCTAssertEqual(Self.tracer.spans.count, 1)
            let span = try XCTUnwrap(Self.tracer.spans.first)

            // basic span recording is tested in the success case

            XCTAssertEqual(span.recordErrorCallCount, 1)
            let error = try XCTUnwrap(errorValue as? ApodiniError)
            XCTAssertEqual(error.option(for: .errorType), .badInput)
            XCTAssertEqual(error.unprefixedMessage, "Bad Input")

            XCTAssertEqual(span.setStatusCallCount, 1)
            let status = try XCTUnwrap(statusValue)
            XCTAssertEqual(status.code, .error)
            XCTAssertEqual(status.message, "Bad Input: Bad Input")

            XCTAssertEqual(span.attributes.count, 5) // no extra attributes recorded
            XCTAssertEqual(span.endCallCount, 1)

            XCTAssertEqual(response.status, .internalServerError)
        }
    }

    func testFailureHandler_whenServerError() throws {
        // Arrange
        var errorValue: Error?
        var statusValue: SpanStatus?
        Self.tracer.startSpanHandler = { span in
            span.recordErrorHandler = { error in
                errorValue = error
            }
            span.setStatusHandler = { status in
                statusValue = status
            }
        }

        // Act
        try Self.app.testable().test(.GET, "/failure?isUserError=0") { response in
            // Assert
            XCTAssertEqual(Self.tracer.spans.count, 1)
            let span = try XCTUnwrap(Self.tracer.spans.first)

            // basic span recording is tested in the success case

            XCTAssertEqual(span.recordErrorCallCount, 1)
            let error = try XCTUnwrap(errorValue as? ApodiniError)
            XCTAssertEqual(error.option(for: .errorType), .serverError)
            XCTAssertEqual(error.unprefixedMessage, "Server Error")

            XCTAssertEqual(span.setStatusCallCount, 1)
            let status = try XCTUnwrap(statusValue)
            XCTAssertEqual(status.code, .error)
            XCTAssertEqual(status.message, "Unexpected Server Error: Server Error")

            XCTAssertEqual(span.attributes.count, 15)
            XCTAssertEqual(
                span.attributes["apodini.request.HTTPVersion"]?.toSpanAttribute(),
                .string("HTTP/1.1")
            )
            XCTAssertEqual(
                span.attributes["apodini.request.HTTPContentType"]?.toSpanAttribute(),
                .string("unknown")
            )
            XCTAssertEqual(
                span.attributes["apodini.request.HTTPBody"]?.toSpanAttribute(),
                .string("")
            )
            XCTAssertEqual(
                span.attributes["apodini.request.url"]?.toSpanAttribute(),
                .string("http://127.0.0.1:8000/failure?isUserError=0")
            )
            XCTAssertEqual(
                span.attributes["apodini.request.url.path"]?.toSpanAttribute(),
                .string("/failure")
            )
            XCTAssertEqual(
                span.attributes["apodini.request.url.pathAndQuery"]?.toSpanAttribute(),
                .string("/failure?isUserError=0")
            )
            XCTAssertEqual(
                span.attributes["apodini.request.parameters.isUserError"]?.toSpanAttribute(),
                .string("false")
            )
            XCTAssertEqual(
                span.attributes["apodini.request.ApodiniNetworkingRequestDescription"]?.toSpanAttribute(),
                .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/failure?isUserError=0>")
            )
            XCTAssertEqual(
                span.attributes["apodini.request.description"]?.toSpanAttribute(),
                .string("<HTTPRequest HTTP/1.1 GET http://127.0.0.1:8000/failure?isUserError=0>")
            )

            XCTAssertEqual(span.endCallCount, 1)

            XCTAssertEqual(response.status, .internalServerError)
        }
    }
}
