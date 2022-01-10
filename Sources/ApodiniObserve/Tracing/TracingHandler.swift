//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

struct TracingHandler<H: Handler>: Handler {
    /// The delegated `Handler`
    let delegate: Delegate<H>

    init(_ handler: H) {
        self.delegate = Delegate(handler, .required)
    }

    func handle() async throws -> H.Response {
        // TODO: wrap the delegates handle() in a span
        try await delegate.instance().handle()
    }
}

struct TracingHandlerInitializer: DelegatingHandlerInitializer {
    func instance<D: Handler>(for delegate: D) throws -> SomeHandler<Never> {
        SomeHandler(TracingHandler(delegate))
    }
}
