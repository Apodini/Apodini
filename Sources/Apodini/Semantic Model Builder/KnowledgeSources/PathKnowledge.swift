//
//  PathKnowledge.swift
//  
//
//  Created by Max Obermeier on 09.05.21.
//

import Foundation


public struct PathComponents: ContextKeyKnowledgeSource {
    public typealias Key = PathComponentContextKey
    
    let value: [PathComponent]
    
    public init(from value: [PathComponent]) {
        self.value = value
    }
}

public struct EndpointPathComponents: KnowledgeSource {
    
    let value: [EndpointPath]
    
    public init<B>(_ blackboard: B) throws where B : Blackboard {
        self.value = blackboard[PathComponents.self].value
            .pathModelBuilder()
            .results.map { component in component.path }
            .scoped(on: blackboard[ParameterCollection.self])
    }
}

extension EndpointPathComponents {
    struct ParameterCollection: Apodini.ParameterCollection, KnowledgeSource {
        let parameters: [AnyEndpointParameter]
        
        init<B>(_ blackboard: B) throws where B : Blackboard {
            self.parameters = blackboard[EndpointParameters.self]
        }
        
        func findParameter(for id: UUID) -> AnyEndpointParameter? {
            parameters.first { parameter in
                parameter.id == id
            }
        }
    }
}

public extension Endpoint {
    var absolutePath: [EndpointPath] {
        self[EndpointPathComponents.self].value
    }
}
