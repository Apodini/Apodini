//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniExtension
import ApodiniNetworking


struct HTTPEndpointKnowledge: KnowledgeSource {
    let method: HTTPMethod
    let pattern: CommunicationalPattern
    let path: [HTTPPathComponent]
    let defaultValues: DefaultValueStore
    
    init<B>(_ blackboard: B) throws where B: Blackboard {
        let knowledge = blackboard[ProtocolAgnosticEndpointKnowledge.self]
        
        self.method = HTTPMethod(knowledge.operation)
        self.pattern = knowledge.pattern
        self.path = knowledge.path.compactMap { element in
            switch element {
            case .root:
                return nil
            case let .parameter(parameter):
                return .namedParameter(parameter.name)
            case let .string(string):
                return .constant(string)
            }
        }
        self.defaultValues = knowledge.defaultValues
    }
}


struct ProtocolAgnosticEndpointKnowledge: KnowledgeSource {
    let operation: Apodini.Operation
    let pattern: CommunicationalPattern
    let path: [EndpointPath]
    let defaultValues: DefaultValueStore
    
    init<B>(_ blackboard: B) throws where B: Blackboard {
        self.operation = blackboard[Apodini.Operation.self]
        self.pattern = blackboard[CommunicationalPattern.self]
        self.path = blackboard[EndpointPathComponentsHTTP.self].value
        self.defaultValues = blackboard[DefaultValueStore.self]
    }
}
