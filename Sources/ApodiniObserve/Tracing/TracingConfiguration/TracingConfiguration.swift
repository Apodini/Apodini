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
        /// The configuration used by `Instrument` instances.
        public let configuration: TracingConfiguration

        init(configuration: TracingConfiguration) {
            self.configuration = configuration
        }
    }

    private let instrumentConfigurations: [InstrumentConfiguration]

    /// Initializes a ``TracingConfiguration`` with the ``InstrumentConfiguration``s for each `Instrument`.
    ///
    /// - Parameter instrumentConfiguration: ``InstrumentConfiguration``s that sepcify the to be used tracing backends.
    public init(_ instrumentConfiguration: InstrumentConfiguration...) {
        self.instrumentConfigurations = instrumentConfiguration
    }

    /// Configures the `Application` with the ``InstrumentConfiguration``s and bootstraps the `InstrumentationSystem`.
    /// - Parameter app: The to be configured `Application`.
    public func configure(_ app: Application) {
        InstrumentationSystem.bootstrap(
            MultiplexInstrument(
                instrumentConfigurations.map { $0.factory(app.eventLoopGroup) }
            )
        )
    }
}
