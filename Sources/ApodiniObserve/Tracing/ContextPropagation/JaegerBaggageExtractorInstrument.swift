//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import InstrumentationBaggage
import Instrumentation

/// An `Instrument` with the sole purpose of extracting and injecting the `jaeger-baggage` header from/to the carrier.
///
/// - Note: This should ideally be [a `Propagator` when it becomes available](https://github.com/apple/swift-distributed-tracing/issues/44).
public struct JaegerBaggageExtractorInstrument: Instrument {
    static let headerKey = "jaeger-baggage"

    public init() {}

    public func extract<Carrier, Extract>(_ carrier: Carrier, into baggage: inout Baggage, using extractor: Extract)
        where Extract: Extractor, Extract.Carrier == Carrier {
        guard let header = extractor.extract(key: Self.headerKey, from: carrier) else {
            return
        }

        baggage[JaegerBaggageKey.self] = JaegerBaggage(
            values: header
                .split(separator: ",")
                .compactMap { entry -> (String, String)? in
                    let pair = entry.split(separator: "=")
                    guard pair.count == 2 else {
                        return nil
                    }
                    return (
                        String(pair[0].trimmingLeadingAndTrailingWhitespace()),
                        String(pair[1].trimmingLeadingAndTrailingWhitespace())
                    )
                }
                .reduce(into: [:]) { $0[$1.0] = $1.1 }
        )
    }

    public func inject<Carrier, Inject>(_ baggage: Baggage, into carrier: inout Carrier, using injector: Inject)
        where Inject: Injector, Inject.Carrier == Carrier {
        guard let jaegerBaggage = baggage[JaegerBaggageKey.self],
              !jaegerBaggage.values.isEmpty
        else { return }

        let headerValue = jaegerBaggage.values
            .map { "\($0.0)=\($0.1)" }
            .joined(separator: ",")

        injector.inject(headerValue, forKey: Self.headerKey, into: &carrier)
    }
}

enum JaegerBaggageKey: BaggageKey {
    typealias Value = JaegerBaggage
}

struct JaegerBaggage {
    var values: [String: String]
}
