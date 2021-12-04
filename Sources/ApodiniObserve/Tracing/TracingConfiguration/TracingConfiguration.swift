//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
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
