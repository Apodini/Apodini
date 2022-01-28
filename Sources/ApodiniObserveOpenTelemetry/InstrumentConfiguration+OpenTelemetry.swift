//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniObserve
import Logging
import OpenTelemetry
import OtlpGRPCSpanExporting
import Tracing

/// Extension that allows for easier setup of the ``InstrumentConfiguration`` for an OpenTelemetry backend.
extension InstrumentConfiguration {
    /// Default OpenTelemetry `Instrument`, exporting spans to an OpenTelemetry collector via gRPC in the OpenTelemetry protocol (OTLP).
    /// - Parameter serviceName: The name of the `WebService` being traced.
    public static func defaultOpenTelemetry(serviceName: String) -> InstrumentConfiguration {
        openTelemetryWithConfig(
            serviceName: serviceName,
            processor: { group in
                let exporter = OtlpGRPCSpanExporter(config: .init(eventLoopGroup: group))
                return OTel.SimpleSpanProcessor(exportingTo: exporter)
            }
        )
    }

    /// OpenTelementry `Instrument` with configuration options.
    /// - Parameters:
    ///   - serviceName: The name of the `WebService` being traced.
    ///   - resourceDetection: Configures how resource attribution may be detected, defaults to `.automatic`.
    ///   - idGenerator: Configures the id generator for trace and span ids.
    ///   - sampler: Configures the sampler to be used, defaults to an *always on* sampler as the root of a parent-based sampler.
    ///   - processor: Configures the span processor to be used for ended spans, defaults to a no-op processor.
    ///   - propagator: Configures the propagator to be used, defaults to a `W3CPropagator`.
    ///   - logger: The Logger used by OTel and its sub-components.
    public static func openTelemetryWithConfig(
        serviceName: String,
        resourceDetection: OTel.ResourceDetection = .automatic(additionalDetectors: []),
        idGenerator: OTelIDGenerator = OTel.RandomIDGenerator(),
        sampler: OTelSampler = OTel.ParentBasedSampler(rootSampler: OTel.ConstantSampler(isOn: true)),
        processor: @escaping (_ group: EventLoopGroup) -> OTelSpanProcessor,
        propagator: OTelPropagator = OTel.W3CPropagator(),
        logger: Logger = Logger(label: "org.apodini.observe.OpenTelemetry")
    ) -> InstrumentConfiguration {
        InstrumentConfiguration { group in
            let otel = OTel(
                serviceName: serviceName,
                eventLoopGroup: group,
                resourceDetection: resourceDetection,
                idGenerator: idGenerator,
                sampler: sampler,
                processor: processor(group),
                propagator: propagator,
                logger: logger
            )

            do {
                try otel.start().wait()
            } catch {
                return nil
            }

            return (otel.tracer(), { try otel.shutdown().wait() })
        }
    }
}
