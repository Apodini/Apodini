//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

public struct DelegateFactoryBasis<H: Handler>: KnowledgeSource {
    public let delegate: Delegate<H>
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self.delegate = Delegate(blackboard[EndpointSource<H>].handler, .required)
    }
}

/// A ``DelegateFactory`` allows for creating ``instance()``s of a ``Delegate``
/// suitable for usage in an ``InterfaceExporter``.
public class DelegateFactory<H: Handler>: KnowledgeSource {
    private let blackboard: Blackboard
    
    private lazy var delegate: Delegate<H> = blackboard[DelegateFactoryBasis<H>.self].delegate
    
    required public init<B>(_ blackboard: B) throws where B: Blackboard {
        self.blackboard = blackboard
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
