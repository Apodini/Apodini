//
//  RelationshipModule.swift
//  
//
//  Created by Max Obermeier on 14.04.21.
//



public struct WebServiceModule<A: TruthAnchor, C: DependencyBased>: DependencyBased {
    
    public static var dependencies: [ContentModule.Type] {
        [PathComponents.self, Operation.self] + C.dependencies
    }
    
    private static var id: ObjectIdentifier {
        ObjectIdentifier(Self.self)
    }
    
    private static var model: WebServiceModel {
        let model = WebServiceStore.elements[Self.id] ?? WebServiceModel()
        WebServiceStore.elements[Self.id] = model
        return model
    }
    
    public init(from store: ModuleStore) throws {
        
    }
}


struct PartialRelationshipSourceCandidates: ContextBased {
    typealias Key = RelationshipSourceCandidateContextKey
    
    let list: [PartialRelationshipSourceCandidate]
    
    init(from value: [PartialRelationshipSourceCandidate]) {
        self.list = value
    }
}

public struct RelationshipSources: ContextBased {
    public typealias Key = RelationshipSourceContextKey
    
    public let list: [Relationship]
    
    public init(from value: [Relationship]) {
        self.list = value
    }
}

public struct RelationshipDestinations: ContextBased {
    public typealias Key = RelationshipDestinationContextKey
    
    public let list: [Relationship]
    
    public init(from value: [Relationship]) {
        self.list = value
    }
}

private struct WebServiceStore {
    static var elements: [ObjectIdentifier: WebServiceModel] = [:]
}
