//
//  ContextBasedKnowledgeSource.swift
//  
//
//  Created by Max Obermeier on 09.05.21.
//

import Foundation


public protocol OptionalContextKeyKnowledgeSource: KnowledgeSource {
    associatedtype Key: OptionalContextKey
    
    init(from value: Key.Value?) throws
}

extension OptionalContextKeyKnowledgeSource {
    public init<B>(_ blackboard: B) throws where B : Blackboard {
        try self.init(from: blackboard[AnyEndpointSource.self].context.get(valueFor: Key.self))
    }
}

public protocol ContextKeyKnowledgeSource: OptionalContextKeyKnowledgeSource where Key: ContextKey {
    init(from value: Key.Value) throws
}

extension ContextKeyKnowledgeSource {
    public init(from value: Key.Value?) throws {
        try self.init(from: value ?? Key.defaultValue)
    }
}
