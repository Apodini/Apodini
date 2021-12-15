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

    private let instrumentConfigurations: [InstrumentConfiguration]

    // Due to the precondition in InstrumentationSystem.bootstrap limiting bootstrapping
    // to once per process, we need to inject the InstrumentationSystem.bootstrapInteral
    // method to allow testing.
    private let instrumentationSystemBootstrap: (Instrument) -> Void

    /// Initializes a ``TracingConfiguration`` with the ``InstrumentConfiguration``s for each `Instrument`.
    ///
    /// - Parameter instrumentConfiguration: ``InstrumentConfiguration``s that sepcify the to be used tracing backends.
    public init(_ instrumentConfiguration: InstrumentConfiguration...) {
        self.instrumentConfigurations = instrumentConfiguration

        // Use the public bootstrap method
        self.instrumentationSystemBootstrap = InstrumentationSystem.bootstrap
    }

    internal init(
        _ instrumentConfiguration: [InstrumentConfiguration],
        instrumentationSystemBootstrap: @escaping (Instrument) -> Void
    ) {
        self.instrumentConfigurations = instrumentConfiguration
        self.instrumentationSystemBootstrap = instrumentationSystemBootstrap
    }

    /// Configures the `Application` with the ``InstrumentConfiguration``s and bootstraps the `InstrumentationSystem`.
    /// - Parameter app: The to be configured `Application`.
    public func configure(_ app: Application) {
        let constructedInstruments = instrumentConfigurations.compactMap { $0.factory(app.eventLoopGroup) }
        
        // Bootstrap the instrumentation system (using the injected boostrap method)
        instrumentationSystemBootstrap(
            MultiplexInstrument(constructedInstruments.map { $0.instrument })
        )
        
        // Add instrument shutdown lifecycle hooks to app
        constructedInstruments
            .compactMap { $0.instrumentShutdown.map(InstrumentConfiguration.Lifecycle.init(instrumentShutdown:)) }
            .forEach { app.lifecycle.use($0) }
        
        // Write configuration to the storage
        app.storage.set(TracingStorageKey.self, to: TracingStorageValue(tracer: app.tracer, configuration: self))
    }
}
