//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import InstrumentationBaggage
import Instrumentation

public struct JaegerBaggageExtractorInstrument: Instrument {
    static let headerKey = "jaeger-baggage"

    public init() {}

    public func extract<Carrier, Extract>(_ carrier: Carrier, into baggage: inout Baggage, using extractor: Extract) where Carrier == Extract.Carrier, Extract: Extractor {
        guard let header = extractor.extract(key: Self.headerKey, from: carrier) else { return }

        baggage[JaegerBaggageKey.self] = JaegerBaggage(
            values: header
                .split(separator: ",")
                .compactMap { entry -> (String, String)? in
                    let pair = entry.split(separator: "=")
                    guard pair.count == 2 else { return nil }
                    return (
                        String(pair[0].trimmingLeadingAndTrailingWhitespace()),
                        String(pair[1].trimmingLeadingAndTrailingWhitespace())
                    )
                }
                .reduce(into: [:]) { $0[$1.0] = $1.1 }
        )
    }

    public func inject<Carrier, Inject>(_ baggage: Baggage, into carrier: inout Carrier, using injector: Inject) where Carrier == Inject.Carrier, Inject: Injector {
        guard let jaegerBaggage = baggage[JaegerBaggageKey.self] else { return }

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
