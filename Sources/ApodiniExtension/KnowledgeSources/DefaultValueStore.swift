//
//  DefaultValueStore.swift
//  
//
//  Created by Max Obermeier on 28.06.21.
//

import Foundation
import Apodini

extension DefaultValueStore: KnowledgeSource {
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self.init(blackboard[EndpointParameters.self])
    }
}
