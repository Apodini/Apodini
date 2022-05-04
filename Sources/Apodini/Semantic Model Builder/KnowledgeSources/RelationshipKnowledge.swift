//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Logging

enum GlobalRelationshipAnchor: TruthAnchor { }

/// Gives access to the `RelationshipSourceCandidateContextKey` declared on an `Endpoint`.
struct EndpointPartialRelationshipSourceCandidates: ContextKeyKnowledgeSource { // swiftlint:disable:this type_name
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
    
    public init<B>(_ sharedRepository: B) throws where B: SharedRepository {
        _ = sharedRepository[RelationshipModelKnowledgeSource.self]
        // we cannot use the `EndpointInjector`'s `endpoint` directly, as this is an incomplete version. Instead we use the version stored
        // on the model
        self.instance = sharedRepository[RelationshipModelKnowledgeSource.EndpointInjector.self].endpoint.reference.resolve()
    }
}

public struct RelationshipModelKnowledgeSource: KnowledgeSource {
    public static var preference: LocationPreference { .global }
    
    public let model: RelationshipWebServiceModel
    
    public init<B>(_ sharedRepository: B) throws where B: SharedRepository {
        let allSharedRepositorys = sharedRepository[SharedRepositorys.self][for: GlobalRelationshipAnchor.self]
        
        for localSharedRepository in allSharedRepositorys {
            _ = localSharedRepository[EndpointInjector.self]
        }
        
        let webService = sharedRepository[WebServiceModelSource.self].model
        webService.finish()
        
        let relationshipBuilder = sharedRepository[RelationshipBuilderSource.self].builder
        let typeIndexBuilder = sharedRepository[TypeIndexBuilderSource.self].builder
        
        // the order of how relationships are built below strongly reflect our strategy
        // on how conflicting definitions shadow each other
        let typeIndex = TypeIndex(from: typeIndexBuilder, buildingWith: relationshipBuilder)
        
        // resolving any type based Relationship creation (inference or Relationship DSL)
        typeIndex.resolve()

        // after we collected any relationships from the `typeIndex.resolve()` step
        // we can construct the final relationship model.
        relationshipBuilder.buildAll()

        sharedRepository[Logger.self].info("\(webService.debugDescription)")
        
        self.model = webService
    }
}

extension RelationshipModelKnowledgeSource {
    struct RelationshipBuilderSource: KnowledgeSource {
        static var preference: LocationPreference { .global }
        
        var builder: RelationshipBuilder
        
        init<B>(_ sharedRepository: B) throws where B: SharedRepository {
            self.builder = RelationshipBuilder(logger: sharedRepository[Logger.self])
        }
    }
    
    struct TypeIndexBuilderSource: KnowledgeSource {
        static var preference: LocationPreference { .global }
        
        var builder: TypeIndexBuilder
        
        init<B>(_ sharedRepository: B) throws where B: SharedRepository {
            self.builder = TypeIndexBuilder(logger: sharedRepository[Logger.self])
        }
    }
    
    struct WebServiceModelSource: KnowledgeSource {
        static var preference: LocationPreference { .global }
        
        var model: RelationshipWebServiceModel
        
        init<B>(_ sharedRepository: B) throws where B: SharedRepository {
            self.model = RelationshipWebServiceModel(sharedRepository)
        }
    }
    
    
    struct EndpointInjector: HandlerKnowledgeSource {
            let endpoint: _AnyRelationshipEndpoint
        
        init<H, B>(from handler: H, _ sharedRepository: B) throws where H: Handler, B: SharedRepository {
            var endpoint = RelationshipEndpoint(handler: handler, sharedRepository: sharedRepository)
            let path = sharedRepository[PathComponents.self].value
            
            sharedRepository[WebServiceModelSource.self].model.addEndpoint(&endpoint, at: path)
            
            // The `ReferenceModule` and `EndpointPathModule` cannot be implemented using one of the standard
            // `KnowledgeSource` protocols as they depend on the `RelationshipWebServiceModel`. This should change
            // once the latter was ported to the standard SharedRepository-Pattern.
            endpoint[ReferenceModule.self].inject(reference: endpoint.reference)
            endpoint[EndpointPathModule.self].inject(absolutePath: endpoint.absolutePath)

            let contentContext = sharedRepository[HandleReturnTypeRootContext.self]

            let contentCandidates = contentContext.get(valueFor: RelationshipSourceCandidateContextKey.self)
            let endpointCandidates = sharedRepository[EndpointPartialRelationshipSourceCandidates.self].list
            
            sharedRepository[RelationshipBuilderSource.self].builder.collect(
                endpoint: endpoint,
                candidates: contentCandidates + endpointCandidates,
                sources: sharedRepository[RelationshipSources.self].list,
                destinations: sharedRepository[RelationshipDestinations.self].list)

            let content = endpoint[HandleReturnType.self].type
            let reference = endpoint[ReferenceModule.self].reference
            let markedDefault = endpoint[Context.self].get(valueFor: DefaultRelationshipContextKey.self) != nil
            let pathParameters = endpoint[EndpointPathModule.self].absolutePath.listPathParameters()
            let operation = endpoint[Operation.self]
            
            sharedRepository[TypeIndexBuilderSource.self].builder.indexContentType(
                content: content,
                reference: reference,
                markedDefault: markedDefault,
                pathParameters: pathParameters,
                operation: operation)
            
            self.endpoint = endpoint
        }
    }
}
