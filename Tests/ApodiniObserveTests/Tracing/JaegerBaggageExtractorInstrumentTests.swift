//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Instrumentation
import InstrumentationBaggage
import XCTApodiniObserve
import XCTest

@testable import ApodiniObserve

// swiftlint:disable implicitly_unwrapped_optional
final class JaegerBaggageExtractorInstrumentTests: XCTestCase {
    private var instrument: JaegerBaggageExtractorInstrument!
    private var carrier: MockCarrier!
    private var injector: MockCarrierInjector!
    private var extractor: MockCarrierExtractor!

    override func setUp() {
        super.setUp()

        instrument = JaegerBaggageExtractorInstrument()
        carrier = MockCarrier()
        injector = MockCarrierInjector()
        extractor = MockCarrierExtractor()
    }

    func testExtract_whenEmpty() {
        // Arrange
        var baggage = Baggage.topLevel

        // Act
        instrument.extract(carrier, into: &baggage, using: extractor)

        // Assert
        XCTAssertNil(baggage[JaegerBaggageKey.self])
    }

    func testExtract_whenSingleEntry() throws {
        // Arrange
        var baggage = Baggage.topLevel
        carrier[JaegerBaggageExtractorInstrument.headerKey] = "foo=bar"

        // Act
        instrument.extract(carrier, into: &baggage, using: extractor)

        // Assert
        let jaegerBaggage = try XCTUnwrap(baggage[JaegerBaggageKey.self])
        XCTAssertEqual(jaegerBaggage.values.count, 1)
        XCTAssertEqual(jaegerBaggage.values["foo"], "bar")
    }

    func testExtract_whenMultipleEntries() throws {
        // Arrange
        var baggage = Baggage.topLevel
        carrier[JaegerBaggageExtractorInstrument.headerKey] = "foo=bar,bar=foo"

        // Act
        instrument.extract(carrier, into: &baggage, using: extractor)

        // Assert
        let jaegerBaggage = try XCTUnwrap(baggage[JaegerBaggageKey.self])
        XCTAssertEqual(jaegerBaggage.values.count, 2)
        XCTAssertEqual(jaegerBaggage.values["foo"], "bar")
        XCTAssertEqual(jaegerBaggage.values["bar"], "foo")
    }

    func testInject_whenEmpty() {
        // Arrange
        var baggage = Baggage.topLevel
        baggage[JaegerBaggageKey.self] = JaegerBaggage(values: [:])

        // Act
        instrument.inject(baggage, into: &carrier, using: injector)

        // Assert
        XCTAssertEqual(carrier.count, 0)
        XCTAssertEqual(carrier[JaegerBaggageExtractorInstrument.headerKey], nil)
    }

    func testInject_whenSingleEntry() throws {
        // Arrange
        var baggage = Baggage.topLevel
        baggage[JaegerBaggageKey.self] = JaegerBaggage(values: ["foo": "bar"])

        // Act
        instrument.inject(baggage, into: &carrier, using: injector)

        // Assert
        XCTAssertEqual(carrier.count, 1)
        let headerValue = try XCTUnwrap(carrier[JaegerBaggageExtractorInstrument.headerKey])
        XCTAssertEqual(headerValue, "foo=bar")
    }

    func testInject_whenMultipleEntries() throws {
        // Arrange
        var baggage = Baggage.topLevel
        baggage[JaegerBaggageKey.self] = JaegerBaggage(values: ["foo": "bar", "bar": "foo"])

        // Act
        instrument.inject(baggage, into: &carrier, using: injector)

        // Assert
        XCTAssertEqual(carrier.count, 1)
        let headerValue = try XCTUnwrap(carrier[JaegerBaggageExtractorInstrument.headerKey])
        XCTAssertTrue(headerValue.contains("foo=bar"))
        XCTAssertTrue(headerValue.contains("bar=foo"))
    }
}
