//
//  MockBlackboard.swift
//  
//
//  Created by Max Obermeier on 10.05.21.
//

#if DEBUG || RELEASE_TESTING
import Foundation
@testable import Apodini

/// A `Blackboard` which only provides access to the `contents` provided on initialization or values
/// that have previously been placed on the board.
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
    /// Create a `WebServiceModel` providing access to an empty global `Blackboard`
    convenience init(mockBlackboard: Blackboard = MockBlackboard()) {
        self.init(mockBlackboard)
    }
}
#endif
