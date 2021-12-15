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
    /// Returns the `Tracer` configured in `Configuration`.
    ///
    /// - Returns: A `Tracer` if the system was configured, and `NoOpTracer` otherwise.
    /// - Note: The returned `Tracer` currently is the plain object returned from the bootstrapped `InstrumentationSystem`. It is not automatically scoped to the current `Handler` yet.
    public var tracer: Tracer {
        InstrumentationSystem.tracer
    }
}
