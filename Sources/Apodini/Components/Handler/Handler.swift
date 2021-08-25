//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import NIO

/// A `Handler` is a `Component` which defines an endpoint and can handle requests.
public protocol Handler: AnyHandlerMetadataBlock, Component {
    /// The type that is returned from the `handle()` method when the component handles a request. The return type of the `handle` method is encoded into the response send out to the client.
    associatedtype Response: ResponseTransformable

    typealias Metadata = AnyHandlerMetadata

    /// A function that is called when a request reaches the `Handler`
    func handle() async throws -> Response
}

// MARK: Metadata DSL
public extension Handler {
    /// Handlers have an empty `AnyHandlerMetadata` by default.
    var metadata: AnyHandlerMetadata {
        Empty()
    }
}

extension Handler {
    /// By default, `Handler`s don't provide any further content
    public var content: some Component {
        EmptyComponent()
    }
}
