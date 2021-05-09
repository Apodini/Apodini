//
//  WebServiceComponent.swift
//  
//
//  Created by Max Obermeier on 07.05.21.
//

import Foundation

/// A type that provides access to the root `WebServiceComponent` of a webservice.
@dynamicMemberLookup
public class WebServiceRoot<A: TruthAnchor>: KnowledgeSource {
    public static var preference: LocationPreference { .global }
    
    public let node: WebServiceComponent<A>
    
    public required init<B>(_ blackboard: B) throws where B: Blackboard {
        self.node = WebServiceComponent(parent: nil, identifier: .root, blackboards: blackboard[Blackboards.self][for: A.self])
    }
    
    subscript<T>(dynamicMember keyPath: KeyPath<WebServiceComponent<A>, T>) -> T {
        node[keyPath: keyPath]
    }
}

/// Provides a structured way to access endpoints of a (partial) web service. Endpoints are organized by their
/// `EndpointPath` and `Operation` attributes.
public class WebServiceComponent<A: TruthAnchor>: KnowledgeSource {
    public let parent: WebServiceComponent<A>?
    public let identifier: EndpointPath
    
    public lazy var endpoints: [Operation: Blackboard] = deriveEndpoints()
    public lazy var children: [WebServiceComponent<A>] = deriveChildren()
    
    public lazy var globalPath: [EndpointPath] = (parent?.globalPath ?? []) + [identifier]
    
    private let blackboards: [Blackboard]
    
    public required init<B>(_ blackboard: B) throws where B: Blackboard {
        // we make sure the WebServiceComponent that is meant to be initilaized here is created by
        // delegating to the WebServiceRoot
        _ = blackboard[WebServiceRoot<A>.self].node.findChild(for: blackboard[PathComponents.self].value, registerSelfToBlackboards: true)
        throw KnowledgeError.instancePresent
    }
    
    fileprivate init(parent: WebServiceComponent<A>?, identifier: EndpointPath, blackboards: [Blackboard]) {
        self.parent = parent
        self.identifier = identifier
        self.blackboards = blackboards
    }
    
    private func deriveEndpoints() -> [Operation: Blackboard] {
        var endpoints = [Operation: Blackboard]()
        for endpoint in blackboards.filter({ blackboard in blackboard[PathComponents.self].value.count == self.globalPath.count - 1 }) {
            endpoints[endpoint[Operation.self]] = endpoint
            endpoint[WebServiceComponent<A>.self] = self
        }
        return endpoints
    }
    
    private func deriveChildren() -> [WebServiceComponent] {
        let children = blackboards.filter { blackboard in
            blackboard[PathComponents.self].value.count > self.globalPath.count - 1
        }
        
        var childrenByPathElement = [EndpointPath: [Blackboard]]()
        
        for blackboard in children {
            let identifier = blackboard[PathComponents.self].value[self.globalPath.count - 1].toEndpointPath()
            var allChildrenWithSameIdentifier = childrenByPathElement[identifier] ?? []
            allChildrenWithSameIdentifier.append(blackboard)
            childrenByPathElement[identifier] = allChildrenWithSameIdentifier
        }
        
        return childrenByPathElement.map { identifier, blackboards in
            WebServiceComponent(parent: self, identifier: identifier, blackboards: blackboards)
        }
    }
}


extension WebServiceComponent: CustomStringConvertible {
    public var description: String {
        var desc = "\(globalPath)"
        for (operation, blackboard) in endpoints {
            desc += "\n  - \(operation): \(blackboard[HandlerDescription.self])"
        }
        for child in children {
            desc += "\n" + child.description
        }
        return desc
    }
}

extension WebServiceComponent {
    func findChild(for path: [PathComponent], registerSelfToBlackboards: Bool = false) -> WebServiceComponent? {
        if path.isEmpty {
            if registerSelfToBlackboards {
                _ = self.endpoints
            }
            return self
        }
        
        for child in children {
            if child.identifier == path[0].toEndpointPath() {
                return child.findChild(for: Array(path[1...]), registerSelfToBlackboards: registerSelfToBlackboards)
            }
        }
        return nil
    }
}
