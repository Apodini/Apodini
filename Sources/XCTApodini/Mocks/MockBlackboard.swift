//
//  MockBlackboard.swift
//  
//
//  Created by Max Obermeier on 10.05.21.
//

import Foundation
@testable import Apodini


public class MockBlackboard: Blackboard {
    private var content: [ObjectIdentifier: KnowledgeSource]
    
    public init(_ contents: (KnowledgeSource.Type, KnowledgeSource)...) {
        var store = [ObjectIdentifier: KnowledgeSource]()
        for content in contents {
            store[ObjectIdentifier(content.0)] = content.1
        }
        self.content = store
    }
    
    public subscript<S>(_ type: S.Type) -> S where S: KnowledgeSource {
        get {
            content[ObjectIdentifier(type)]! as! S
        }
        set {
            content[ObjectIdentifier(type)] = newValue
        }
    }
    
    public func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource {
        self[type]
    }
}

public extension WebServiceModel {
    convenience init(mockBlackboard: Blackboard = MockBlackboard()) {
        self.init(mockBlackboard)
    }
}
