//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Tracing

/// The `Configuration` for the `InstrumentationSystem`.
public final class TracingConfiguration: Configuration {
    /// The storage key for Tracing-related information.
    public struct TracingStorageKey: StorageKey {
        public typealias Value = TracingStorageValue
    }

    /// The value key for Tracing-related information.
    public struct TracingStorageValue {
        /// The application `Tracer`.
        public let tracer: Tracer
        /// The configuration used by `Instrument` instances.
        public let configuration: TracingConfiguration

        init(tracer: Tracer, configuration: TracingConfiguration) {
            self.tracer = tracer
            self.configuration = configuration
        }
    }

    private let tracerConfigurations: [TracerConfiguration]

    // Due to the precondition in InstrumentationSystem.bootstrap limiting bootstrapping
    // to once per process, we need to inject the InstrumentationSystem.bootstrapInteral
    // method to allow testing.
    private let instrumentationSystemBootstrap: (Instrument) -> Void

    /// Initializes a ``TracingConfiguration`` with the ``TracerConfiguration``s for each `Tracer`.
    ///
    /// - Parameter tracerConfigurations: ``TracerConfiguration``s that sepcify the to be used tracing backends.
    public init(_ tracerConfigurations: TracerConfiguration...) {
        self.tracerConfigurations = tracerConfigurations

        // Use the public bootstrap method
        self.instrumentationSystemBootstrap = InstrumentationSystem.bootstrap
    }

    internal init(
        _ tracerConfigurations: [TracerConfiguration],
        instrumentationSystemBootstrap: @escaping (Instrument) -> Void
    ) {
        self.tracerConfigurations = tracerConfigurations
        self.instrumentationSystemBootstrap = instrumentationSystemBootstrap
    }

    /// Configures the `Application` with the ``TracerConfiguration``s and bootstraps the `InstrumentationSystem`.
    /// - Parameter app: The to be configured `Application`.
    public func configure(_ app: Application) {
        let constructedTracers = tracerConfigurations.compactMap { $0.factory(app.eventLoopGroup) }
        
        // Bootstrap the instrumentation system (using the injected boostrap method)
        if constructedTracers.count == 1 {
            instrumentationSystemBootstrap(
                constructedTracers[0].tracer
            )
        } else {
            instrumentationSystemBootstrap(
                MultiplexInstrument(constructedTracers.map { $0.tracer })
            )
        }
        
        // Add instrument shutdown lifecycle hooks to app
        constructedTracers
            .compactMap { $0.tracerShutdown.map(TracerConfiguration.Lifecycle.init(tracerShutdown:)) }
            .forEach { app.lifecycle.use($0) }
        
        // Write configuration to the storage
        app.storage.set(TracingStorageKey.self, to: TracingStorageValue(tracer: app.tracer, configuration: self))
    }
}
