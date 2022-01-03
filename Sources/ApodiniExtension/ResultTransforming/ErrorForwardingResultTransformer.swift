//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public struct ErrorForwardingResultTransformer<R: ResultTransformer>: ResultTransformer {
    let wrapped: R
    let forwarder: ErrorForwarder

    public init(wrapped: R, forwarder: ErrorForwarder) {
        self.wrapped = wrapped
        self.forwarder = forwarder
    }

    public func transform(input: R.Input) throws -> R.Output {
        try wrapped.transform(input: input)
    }

    public func handle(error: ApodiniError) -> ErrorHandlingStrategy<R.Output, R.Failure> {
        forwarder.forward?(error)
        return wrapped.handle(error: error)
    }
}
