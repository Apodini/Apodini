//
//  RelationshipModule.swift
//  
//
//  Created by Max Obermeier on 14.04.21.
//


struct PartialRelationshipSourceCandidates: ContextKeyKnowledgeSource {
    typealias Key = RelationshipSourceCandidateContextKey
    
    let list: [PartialRelationshipSourceCandidate]
    
    init(from value: [PartialRelationshipSourceCandidate]) {
        self.list = value
    }
}

public struct RelationshipSources: ContextKeyKnowledgeSource {
    public typealias Key = RelationshipSourceContextKey
    
    public let list: [Relationship]
    
    public init(from value: [Relationship]) {
        self.list = value
    }
}

public struct RelationshipDestinations: ContextKeyKnowledgeSource {
    public typealias Key = RelationshipDestinationContextKey
    
    public let list: [Relationship]
    
    public init(from value: [Relationship]) {
        self.list = value
    }
}

private enum WebServiceStore {
    static var elements: [ObjectIdentifier: WebServiceModel] = [:]
}
