//
//  PathKnowledge.swift
//  
//
//  Created by Max Obermeier on 09.05.21.
//

import Foundation


struct PathComponents: ContextKeyKnowledgeSource {
    public typealias Key = PathComponentContextKey
    
    let value: [PathComponent]
    
    public init(from value: [PathComponent]) {
        self.value = value
    }
}
