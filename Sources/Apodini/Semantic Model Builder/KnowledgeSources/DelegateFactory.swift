//
//  DelegateFactory.swift
//
//
//  Created by Max Obermeier on 19.07.21.
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
