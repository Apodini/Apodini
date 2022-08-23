//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

/// A type that provides access to the root `WebServiceComponent` of a webservice.
@dynamicMemberLookup
public class WebServiceRoot<A: TruthAnchor>: KnowledgeSource {
    public static var preference: LocationPreference { .global }
    
    public let node: WebServiceComponent<A>
    
    public required init<B>(_ sharedRepository: B) throws where B: SharedRepository {
        self.node = WebServiceComponent(
            parent: nil,
            identifier: .root,
            sharedRepositorys: sharedRepository[SharedRepositorys.self][for: A.self]
        )
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
    
    public lazy var endpoints: [Operation: SharedRepository] = deriveEndpoints()
    public lazy var children: [WebServiceComponent<A>] = deriveChildren()
    
    public lazy var globalPath: [EndpointPath] = (parent?.globalPath ?? []) + [identifier]
    
    private let sharedRepositorys: [SharedRepository]
    
    public required init<B>(_ sharedRepository: B) throws where B: SharedRepository {
        // we make sure the WebServiceComponent that is meant to be initilaized here is created by
        // delegating to the WebServiceRoot
        _ = sharedRepository[WebServiceRoot<A>.self].node.findChild(
            for: sharedRepository[PathComponents.self].value,
            registerSelfToSharedRepositorys: true
        )
        throw KnowledgeError.instancePresent
    }
    
    fileprivate init(parent: WebServiceComponent<A>?, identifier: EndpointPath, sharedRepositorys: [SharedRepository]) {
        self.parent = parent
        self.identifier = identifier
        self.sharedRepositorys = sharedRepositorys
    }
    
    private func deriveEndpoints() -> [Operation: SharedRepository] {
        var endpoints = [Operation: SharedRepository]()
        for endpoint in sharedRepositorys.filter({ sharedRepository in
            sharedRepository[PathComponents.self].value.count == self.globalPath.count - 1
        }) {
            endpoints[endpoint[Operation.self]] = endpoint
            endpoint[WebServiceComponent<A>.self] = self
        }
        return endpoints
    }
    
    private func deriveChildren() -> [WebServiceComponent] {
        let children = sharedRepositorys.filter { sharedRepository in
            sharedRepository[PathComponents.self].value.count > self.globalPath.count - 1
        }
        
        var childrenByPathElement = [EndpointPath: [SharedRepository]]()
        
        for sharedRepository in children {
            let identifier = sharedRepository[PathComponents.self].value[self.globalPath.count - 1].toEndpointPath()
            var allChildrenWithSameIdentifier = childrenByPathElement[identifier] ?? []
            allChildrenWithSameIdentifier.append(sharedRepository)
            childrenByPathElement[identifier] = allChildrenWithSameIdentifier
        }
        
        return childrenByPathElement.map { identifier, sharedRepositorys in
            WebServiceComponent(parent: self, identifier: identifier, sharedRepositorys: sharedRepositorys)
        }
    }
}


extension WebServiceComponent: CustomStringConvertible {
    public var description: String {
        var desc = "\(globalPath)"
        for (operation, sharedRepository) in endpoints {
            desc += "\n  - \(operation): \(sharedRepository[HandlerDescription.self])"
        }
        for child in children {
            desc += "\n" + child.description
        }
        return desc
    }
}

extension WebServiceComponent {
    func findChild(for path: [PathComponent], registerSelfToSharedRepositorys: Bool = false) -> WebServiceComponent? {
        if path.isEmpty {
            if registerSelfToSharedRepositorys {
                _ = self.endpoints
            }
            return self
        }
        
        for child in children {
            if child.identifier == path[0].toEndpointPath() {
                return child.findChild(for: Array(path[1...]), registerSelfToSharedRepositorys: registerSelfToSharedRepositorys)
            }
        }
        return nil
    }
}
