//
//  EndpointParameterMappings.swift
//  
//
//  Created by Max Obermeier on 27.06.21.
//

import Apodini
import Foundation


public struct EndpointParametersById: KnowledgeSource {
    public let parameters: [UUID: AnyEndpointParameter]
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        self.parameters = blackboard[EndpointParameters.self].reduce(into: [UUID: AnyEndpointParameter](), { storage, parameter in
            storage[parameter.id] = parameter
        })
    }
}
