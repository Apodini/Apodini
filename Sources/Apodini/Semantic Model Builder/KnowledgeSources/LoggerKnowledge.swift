//
//  LoggerKnowledge.swift
//  
//
//  Created by Max Obermeier on 14.06.21.
//

import Foundation
import Logging

extension Logger: KnowledgeSource {
    public static var preference: LocationPreference { .global }
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self = blackboard[Application.self].logger
    }
}
