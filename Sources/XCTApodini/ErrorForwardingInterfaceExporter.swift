//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniExtension

/// An `InterfaceExporter` that attaches a error forwarding closure to all endpoints.
public final class ErrorForwardingInterfaceExporter: InterfaceExporter {
    let forwardClosure: (Error) -> Void

    public init(forwardClosure: @escaping (Error) -> Void) {
        self.forwardClosure = forwardClosure
    }

    public func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
        endpoint[ErrorForwarder.self] = try! ErrorForwarder(from: forwardClosure)
    }

    public func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        endpoint[ErrorForwarder.self] = try! ErrorForwarder(from: forwardClosure)
    }
}
