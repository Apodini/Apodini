//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Tracing

extension Application {
    /// Returns the `Instrument` configured in `Configuration`.
    ///
    /// - Returns: An `Instrument` if the system was configured. Else, crashes the application.
    public var instrument: Instrument {
        guard let instrument = storage[TracingConfiguration.TracingStorageKey.self]?.instrument else {
            fatalError("Tracing wasn't configured correctly")
        }
        return instrument
    }

    /// Returns the `Tracer` configured in `Configuration`.
    ///
    /// - Returns: A `Tracer` if the system was configured. Else, crashes the application.
    public var tracer: Tracer {
        guard let tracer = storage[TracingConfiguration.TracingStorageKey.self]?.tracer else {
            fatalError("Tracing wasn't configured correctly")
        }
        return tracer
    }
}
