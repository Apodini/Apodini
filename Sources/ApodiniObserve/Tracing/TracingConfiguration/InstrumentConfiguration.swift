//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Tracing

/// Factory that produces an `Instrument` and an optional closure that gets called when the `Application` shuts down.
public typealias InstrumentFactory = (_ group: EventLoopGroup) -> (instrument: Instrument, instrumentShutdown: InstrumentShutdown?)?

/// Closure to shutdown an instrumentation backend.
public typealias InstrumentShutdown = () throws -> Void

/// A configuration for an `Instrument`.
public struct InstrumentConfiguration {
    struct Lifecycle: LifecycleHandler {
        let instrumentShutdown: InstrumentShutdown
        
        func shutdown(_ application: Application) throws {
            try instrumentShutdown()
        }
    }
    
    /// The factory which creates the `Instrument`.
    public let factory: InstrumentFactory

    /// Initializes an ``InstrumentConfiguration`` using a factory.
    /// - Parameter factory: The ``InstrumentFactory`` producing the`Instrument` that should be used as a tracing backend and an optional closure that gets called when the `Application` shuts down.
    public init(_ factory: @escaping InstrumentFactory) {
        self.factory = factory
    }

    /// Initializes an ``InstrumentConfiguration`` from an `Instrument`.
    /// - Parameter instrument: The `Instrument` that should be used as a tracing backend.
    public init(_ instrument: Instrument) {
        self.factory = { _ in (instrument, nil) }
    }
}
