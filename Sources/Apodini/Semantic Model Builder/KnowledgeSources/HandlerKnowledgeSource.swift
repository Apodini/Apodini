//
//  HandlerKnowledgeSource.swift
//  
//
//  Created by Max Obermeier on 07.05.21.
//

import Foundation

/// A helper protocol that provides typed access to the `Handler` stored in `AnyEndpointSource`.
public protocol HandlerKnowledgeSource: KnowledgeSource {
    init<H: Handler, B: Blackboard>(from handler: H, _ blackboard: B) throws
}

extension HandlerKnowledgeSource {
    /// Calls `HandlerKnowledgeSource.init` using the `Handler` extracted from `AnyEndpointSource`.
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        let anyEndpointSource = blackboard[AnyEndpointSource.self]
        
        self = try anyEndpointSource.create(Self.self, using: blackboard)
    }
}
