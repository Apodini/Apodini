//
//  ResponseTypeKnowledge.swift
//  
//
//  Created by Max Obermeier on 09.05.21.
//

import Foundation

public struct ResponseType: KnowledgeSource {
    public let type: Encodable.Type
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self.type = blackboard[HandleReturnType.self].type
    }
}
