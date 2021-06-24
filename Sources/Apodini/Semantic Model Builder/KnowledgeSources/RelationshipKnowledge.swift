//
//  RelationshipComponent.swift
//  
//
//  Created by Max Obermeier on 14.06.21.
//

import Foundation
import Logging

enum GlobalRelationshipAnchor: TruthAnchor { }

struct PartialRelationshipSourceCandidates: ContextKeyKnowledgeSource {
    typealias Key = RelationshipSourceCandidateContextKey
    
    let list: [PartialRelationshipSourceCandidate]
    
    init(from value: [PartialRelationshipSourceCandidate]) {
        self.list = value
    }
}

struct RelationshipSources: ContextKeyKnowledgeSource {
    typealias Key = RelationshipSourceContextKey
    
    let list: [Relationship]
    
    init(from value: [Relationship]) {
        self.list = value
    }
}

struct RelationshipDestinations: ContextKeyKnowledgeSource {
    typealias Key = RelationshipDestinationContextKey
    
    let list: [Relationship]
    
    init(from value: [Relationship]) {
        self.list = value
    }
}

public struct AnyRelationshipEndpointInstance: KnowledgeSource {
    public let instance: AnyRelationshipEndpoint
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        _ = blackboard[RelationshipModelKnowledgeSource.self]
        // we cannot use the `EndpointInjector`'s `endpoint` directly, as this is an incomplete version. Instead we use the version stored
        // on the model
        self.instance = blackboard[RelationshipModelKnowledgeSource.EndpointInjector.self].endpoint.reference.resolve()
    }
}

public struct RelationshipModelKnowledgeSource: KnowledgeSource {
    public static var preference: LocationPreference { .global }
    
    public let model: RelationshipWebServiceModel
    
    public init<B>(_ blackboard: B) throws where B: Blackboard {
        let allBlackboards = blackboard[Blackboards.self][for: GlobalRelationshipAnchor.self]
        
        for localBlackboard in allBlackboards {
            _ = localBlackboard[EndpointInjector.self]
        }
        
        let webService = blackboard[WebServiceModelSource.self].model
        webService.finish()
        
        let relationshipBuilder = blackboard[RelationshipBuilderSource.self].builder
        let typeIndexBuilder = blackboard[TypeIndexBuilderSource.self].builder
        
        // the order of how relationships are built below strongly reflect our strategy
        // on how conflicting definitions shadow each other
        let typeIndex = TypeIndex(from: typeIndexBuilder, buildingWith: relationshipBuilder)
        
        // resolving any type based Relationship creation (inference or Relationship DSL)
        typeIndex.resolve()

        // after we collected any relationships from the `typeIndex.resolve()` step
        // we can construct the final relationship model.
        relationshipBuilder.buildAll()

        blackboard[Logger.self].info("\(webService.debugDescription)")
        
        self.model = webService
    }
}

extension RelationshipModelKnowledgeSource {
    struct RelationshipBuilderSource: KnowledgeSource {
        static var preference: LocationPreference { .global }
        
        var builder: RelationshipBuilder
        
        init<B>(_ blackboard: B) throws where B: Blackboard {
            self.builder = RelationshipBuilder(logger: blackboard[Logger.self])
        }
    }
    
    struct TypeIndexBuilderSource: KnowledgeSource {
        static var preference: LocationPreference { .global }
        
        var builder: TypeIndexBuilder
        
        init<B>(_ blackboard: B) throws where B: Blackboard {
            self.builder = TypeIndexBuilder(logger: blackboard[Logger.self])
        }
    }
    
    struct WebServiceModelSource: KnowledgeSource {
        static var preference: LocationPreference { .global }
        
        var model: RelationshipWebServiceModel
        
        init<B>(_ blackboard: B) throws where B: Blackboard {
            self.model = RelationshipWebServiceModel(blackboard)
        }
    }
    
    
    struct EndpointInjector: HandlerKnowledgeSource {
            let endpoint: _AnyRelationshipEndpoint
        
        init<H, B>(from handler: H, _ blackboard: B) throws where H: Handler, B: Blackboard {
            var endpoint = RelationshipEndpoint(handler: handler, blackboard: blackboard)
            let path = blackboard[PathComponents.self].value
            
            blackboard[WebServiceModelSource].model.addEndpoint(&endpoint, at: path)
            
            // The `ReferenceModule` and `EndpointPathModule` cannot be implemented using one of the standard
            // `KnowledgeSource` protocols as they depend on the `RelationshipWebServiceModel`. This should change
            // once the latter was ported to the standard Blackboard-Pattern.
            endpoint[ReferenceModule.self].inject(reference: endpoint.reference)
            endpoint[EndpointPathModule.self].inject(absolutePath: endpoint.absolutePath)
            
            blackboard[RelationshipBuilderSource].builder.collect(
                endpoint: endpoint,
                candidates: blackboard[PartialRelationshipSourceCandidates.self].list,
                sources: blackboard[RelationshipSources.self].list,
                destinations: blackboard[RelationshipDestinations.self].list)
            
            let content = endpoint[HandleReturnType.self].type
            let reference = endpoint[ReferenceModule.self].reference
            let markedDefault = endpoint[Context.self].get(valueFor: DefaultRelationshipContextKey.self) != nil
            let pathParameters = endpoint[EndpointPathModule.self].absolutePath.listPathParameters()
            let operation = endpoint[Operation.self]
            
            blackboard[TypeIndexBuilderSource.self].builder.indexContentType(
                content: content,
                reference: reference,
                markedDefault: markedDefault,
                pathParameters: pathParameters,
                operation: operation)
            
            self.endpoint = endpoint
        }
    }
}
