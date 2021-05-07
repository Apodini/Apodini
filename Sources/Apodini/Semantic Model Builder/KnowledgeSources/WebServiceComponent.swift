//
//  WebServiceComponent.swift
//  
//
//  Created by Max Obermeier on 07.05.21.
//

import Foundation

public class WebServiceComponent<A: TruthAnchor>: KnowledgeSource {
    public static var preference: LocationPreference {
        .global
    }
    
    public let parent: WebServiceComponent<A>?
    public let identifier: EndpointPath
    
    public lazy var endpoints: [Operation: Blackboard] = deriveEndpoints()
    public lazy var children: [WebServiceComponent<A>] = deriveChildren()
    
    public lazy var globalPath: [EndpointPath] = (parent?.globalPath ?? []) + [identifier]
    
    private let blackboards: [Blackboard]
    
    required public init<B>(_ blackboard: B) throws where B : Blackboard {
        self.identifier = .root
        self.parent = nil
        
        self.blackboards = blackboard[Blackboards.self][for: A.self]
    }
    
    private init(parent: WebServiceComponent<A>, identifier: EndpointPath, blackboards: [Blackboard]) {
        self.parent = parent
        self.identifier = identifier
        self.blackboards = blackboards
    }
    
    private func deriveEndpoints() -> [Operation: Blackboard] {
        var endpoints = [Operation: Blackboard]()
        for endpoint in blackboards.filter({ blackboard in blackboard[PathComponents.self].value.count == self.globalPath.count }) {
            endpoints[endpoint[Operation.self]] = endpoint
        }
        return endpoints
    }
    
    private func deriveChildren() -> [WebServiceComponent] {
        let children = blackboards.filter({ blackboard in blackboard[PathComponents.self].value.count > self.globalPath.count })
        
        var childrenByPathElement = [EndpointPath: [Blackboard]]()
        
        for blackboard in children {
            let identifier = blackboard[PathComponents.self].value[self.globalPath.count].toEndpointPath()
            var allChildrenWithSameIdentifier = childrenByPathElement[identifier] ?? []
            allChildrenWithSameIdentifier.append(blackboard)
            childrenByPathElement[identifier] = allChildrenWithSameIdentifier
        }
        
        return childrenByPathElement.map { (identifier, blackboards) in
            WebServiceComponent(parent: self, identifier: identifier, blackboards: blackboards) }
    }
}
