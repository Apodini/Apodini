//
//  Delegate.swift
//  
//
//  Created by Max Obermeier on 09.07.21.
//

import Foundation
import Apodini

extension Delegate: KnowledgeSource where D: Handler {
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self = Delegate(blackboard[EndpointSource<D>.self].handler, .required)
    }
}

public extension Endpoint {
    /// The a pre-prepared `Delegate` to be used for evaluating `Request`s on this `Endpoint`.
    ///
    /// - Note: Copy this instance to to your local connection-context.
    var delegate: Delegate<H> {
        self[Delegate<H>.self]
    }
}
