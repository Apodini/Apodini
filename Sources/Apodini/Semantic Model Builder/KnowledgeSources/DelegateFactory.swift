//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A ``DelegateFactory`` allows for creating ``instance()``s of a ``Delegate``
/// suitable for usage in an ``InterfaceExporter``.
public struct DelegateFactory<H: Handler>: KnowledgeSource {
    private let delegate: Delegate<H>
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self.delegate = Delegate(blackboard[EndpointSource<H>].handler, .required)
    }
    
    /// Creates one instance of the ``Delegate``.
    ///
    /// - Note: Use a new instance for each client-connection! Otherwise data may be shared between
    /// all clients using the same instance.
    public func instance() -> Delegate<H> {
        var delegate = self.delegate
        delegate.activate()
        return delegate
    }
}
