//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

#if DEBUG || RELEASE_TESTING
@testable import ApodiniObserve
@testable import Instrumentation

extension TracingConfiguration {
    /// A testable `TracingConfiguration`.
    ///
    /// The configuration uses the injected `InstrumentationSystem.bootstrapInteral` method to
    /// enable bootstrapping multiple times per process.
    ///
    /// - Parameter instrumentConfiguration: ``InstrumentConfiguration``s that sepcify the to be used tracing backends.
    public static func testable(_ instrumentConfiguration: InstrumentConfiguration...) -> TracingConfiguration {
        TracingConfiguration(
            instrumentConfiguration,
            instrumentationSystemBootstrap: { InstrumentationSystem.bootstrapInternal($0) }
        )
    }
}
#endif
