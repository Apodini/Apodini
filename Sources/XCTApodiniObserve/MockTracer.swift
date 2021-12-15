//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Tracing

public struct MockTracer: Tracer {
    public init() {}

    public func startSpan(_ operationName: String, baggage: Baggage, ofKind kind: SpanKind, at time: DispatchWallTime) -> Span {
        MockSpan(
            operationName: operationName,
            baggage: baggage,
            kind: kind,
            time: time
        )
    }

    public func forceFlush() {}

    public func extract<Carrier, Extract>(
        _ carrier: Carrier,
        into baggage: inout Baggage,
        using extractor: Extract
    ) where Carrier == Extract.Carrier, Extract: Extractor {}

    public func inject<Carrier, Inject>(
        _ baggage: Baggage,
        into carrier: inout Carrier,
        using injector: Inject
    ) where Carrier == Inject.Carrier, Inject: Injector {}

    public final class MockSpan: Span {
        public let operationName: String
        public let baggage: Baggage
        public let kind: SpanKind
        public let time: DispatchWallTime
        public let isRecording = false

        public init(
            operationName: String,
            baggage: Baggage,
            kind: SpanKind,
            time: DispatchWallTime
        ) {
            self.operationName = operationName
            self.baggage = baggage
            self.kind = kind
            self.time = time
        }

        public func setStatus(_ status: SpanStatus) {}

        public func addLink(_ link: SpanLink) {}

        public func addEvent(_ event: SpanEvent) {}

        public func recordError(_ error: Error) {}

        public var attributes: SpanAttributes = [:]

        public var endCallCount = 0
        public func end(at time: DispatchWallTime) {
            endCallCount += 1
        }
    }
}
