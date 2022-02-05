//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Tracing

/// Factory that produces an `Tracer` and an optional closure that gets called when the `Application` shuts down.
public typealias TracerFactory = (_ group: EventLoopGroup) -> (tracer: Tracer, tracerShutdown: TracerShutdown?)?

/// Closure to shutdown a tracing backend.
public typealias TracerShutdown = () throws -> Void

/// A configuration for a `Tracer`.
public struct TracerConfiguration {
    struct Lifecycle: LifecycleHandler {
        let tracerShutdown: TracerShutdown
        
        func shutdown(_ application: Application) throws {
            try tracerShutdown()
        }
    }
    
    /// The factory which creates the `Tracer`.
    public let factory: TracerFactory

    /// Initializes an ``TracerConfiguration`` using a factory.
    /// - Parameter factory: The ``TracerFactory`` producing the`Tracer` that should be used as a tracing backend and an optional closure that gets called when the `Application` shuts down.
    public init(_ factory: @escaping TracerFactory) {
        self.factory = factory
    }

    /// Initializes an ``TracerConfiguration`` from a `Tracer`.
    /// - Parameter tracer: The `Tracer` that should be used as a tracing backend.
    public init(_ tracer: Tracer) {
        self.factory = { _ in (tracer, nil) }
    }
}
