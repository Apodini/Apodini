//
//  OpenAPIPathBuilder.swift
//  
//
//  Created by Lorena Schlesinger on 15.11.20.
//

import Vapor

let DEFAULT_OPEN_API_PATH_SEPARATOR = "/"

// TODO: Decide on common PathBuilder together with RESTPathBuilder
struct OpenAPIPathBuilder: PathBuilder {
    public private(set) var pathComponents: [Vapor.PathComponent] = []
    
    var fullPath: String {
        pathComponents.map { pathComponent in
            var pathValue = pathComponent.description
            // TODO: hacky! we are using the internals of `Vapor.PathComponent` here (e.g., offset: 2)...
            if case .parameter = pathComponent {
                pathValue = "{\(pathComponent.description[pathComponent.description.index(pathComponent.description.startIndex, offsetBy: 2)...])}"
            }
            return pathValue
        }.joined(separator: DEFAULT_OPEN_API_PATH_SEPARATOR)
    }
    
    var parameters: [String] {
        pathComponents.filter { pathComponent in
            if case .parameter = pathComponent { return true } else { return false } }
            .map { pathComponent in
                String(pathComponent.description[pathComponent.description.index(pathComponent.description.startIndex, offsetBy: 2)...]) // TODO: hacky!
        }
    }
    
    init(_ pathComponents: [PathComponent]) {
        for pathComponent in pathComponents {
            if let pathComponent = pathComponent as? _PathComponent {
                pathComponent.append(to: &self)
            }
        }
    }
    
    mutating func append(_ string: String) {
        let pathComponent = string.lowercased()
        // TODO: this is a hack because pathComponents in `Group`s
        // don't seem to check for `identifiers` (i.e., parameters yet)
        if pathComponent.contains(":") {
            pathComponents.append(.parameter(pathComponent))
        } else {
            pathComponents.append(.constant(pathComponent))
        }
    }
    
    mutating func append<T>(_ identifiier: Identifier<T>) where T : Identifiable {
        let pathComponent = identifiier.identifier
        pathComponents.append(.parameter(pathComponent))
    }
}
