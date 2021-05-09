//
//  ResponseTransformerKnowledge.swift
//  
//
//  Created by Max Obermeier on 09.05.21.
//

import Foundation

struct ResponseTransformersReturnType: ContextKeyKnowledgeSource {
    typealias Key = ResponseTransformerContextKey
    
    let type: Encodable.Type?
    
    init(from value: [LazyAnyResponseTransformer]) {
        self.type = value.responseType
    }
}

public struct ResponseType: KnowledgeSource {
    public let type: Encodable.Type
    
    public init<B>(_ blackboard: B) throws where B : Blackboard {
        self.type = blackboard[ResponseTransformersReturnType.self].type ?? blackboard[HandleReturnType.self].type
    }
}
