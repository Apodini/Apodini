//
//  RelationshipModule.swift
//  
//
//  Created by Max Obermeier on 14.04.21.
//


@available(*, deprecated, message: """
    Replaced by 'WebServiceComponent'/'WebServiceRoot'.
    Those are lazy and properly integrated with the Blackboard-Pattern and thus don't require manual support by the 'SemanticModelBuilder'.
""")
public struct WebServiceModule<A: TruthAnchor, C: KnowledgeSource>: KnowledgeSource {
    private static var id: ObjectIdentifier {
        ObjectIdentifier(Self.self)
    }
    
    private static var model: WebServiceModel {
        let model = WebServiceStore.elements[Self.id] ?? WebServiceModel()
        WebServiceStore.elements[Self.id] = model
        return model
    }
    
    public init<B>(_ blackboard: B) throws where B: Blackboard { }
}


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
