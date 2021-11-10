//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import OpenTelemetry
import OtlpGRPCSpanExporting
import Tracing

public class TracingConfiguration: Configuration {
    public struct TracingStorageKey: StorageKey {
        public typealias Value = TracingStorageValue
    }

    public struct TracingStorageValue {
        public let configuration: TracingConfiguration

        init(configuration: TracingConfiguration) {
            self.configuration = configuration
        }
    }

    private let instrumentConfigurations: [InstrumentConfiguration]

    public init(_ instrumentConfiguration: InstrumentConfiguration...) {
        self.instrumentConfigurations = instrumentConfiguration
    }

    public func configure(_ app: Application) {
        InstrumentationSystem.bootstrap(
            MultiplexInstrument(
                instrumentConfigurations.map { $0.factory(app.eventLoopGroup) }
            )
        )
    }
}

public struct InstrumentConfiguration {
    public let factory: (_ group: EventLoopGroup) -> Instrument

    public init(_ factory: @escaping (_ group: EventLoopGroup) -> Instrument) {
        self.factory = factory
    }

    public init(_ instrument: Instrument) {
        self.factory = { _ in instrument }
    }
}

extension InstrumentConfiguration {
    /// Default OpenTelemetry `Instrument`, exporting spans to an OpenTelemetry collector via gRPC in the OpenTelemetry protocol (OTLP).
    public static var defaultOpenTelemetry: InstrumentConfiguration {
        InstrumentConfiguration { group in
            let exporter = OtlpGRPCSpanExporter(config: .init(eventLoopGroup: group))
            let processor = OTel.SimpleSpanProcessor(exportingTo: exporter)
            let otel = OTel(serviceName: "TODO", eventLoopGroup: group, processor: processor)

            try! otel.start().wait()

            // TODO: What about shutdown
            return otel.tracer()
        }
    }

    public static func openTelemetryWithConfig(
        resourceDetection: OTel.ResourceDetection = .automatic(additionalDetectors: []),
        idGenerator: OTelIDGenerator = OTel.RandomIDGenerator(),
        sampler: OTelSampler = OTel.ParentBasedSampler(rootSampler: OTel.ConstantSampler(isOn: true)),
        processor: @escaping (_ group: EventLoopGroup) -> OTelSpanProcessor,
        propagator: OTelPropagator = OTel.W3CPropagator(),
        logger: Logger = Logger(label: "OTel")
    ) -> InstrumentConfiguration {
        InstrumentConfiguration { group in
            let otel = OTel(
                serviceName: "TODO",
                eventLoopGroup: group,
                resourceDetection: resourceDetection,
                idGenerator: idGenerator,
                sampler: sampler,
                processor: processor(group),
                propagator: propagator,
                logger: logger
            )

            try! otel.start().wait()

            // TODO: What about shutdown
            return otel.tracer()
        }
    }
}
