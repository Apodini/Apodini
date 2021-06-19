//
//  WebServiceModel.swift
//  
//
//  Created by Max Obermeier on 14.06.21.
//

import Foundation

public struct WebServiceModel: Blackboard {
    private let blackboard: Blackboard
    
    internal init(blackboard: Blackboard) {
        self.blackboard = blackboard
    }
    
    public subscript<S>(_ type: S.Type) -> S where S: KnowledgeSource {
        get {
            blackboard[type]
        }
        nonmutating set {
            blackboard[type] = newValue
        }
    }
    
    public func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource {
        try blackboard.request(type)
    }
}
