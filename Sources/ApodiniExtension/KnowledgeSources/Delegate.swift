//
//  Delegate.swift
//  
//
//  Created by Max Obermeier on 09.07.21.
//

import Foundation
import Apodini

extension Delegate: KnowledgeSource where D: Handler {
    public init<B>(_ blackboard: B) throws where B : Blackboard {
        self = Delegate(blackboard[EndpointSource<D>.self].handler, .required)
    }
}

public extension Endpoint {
    var delegate: Delegate<H> {
        self[Delegate<H>.self]
    }
}
