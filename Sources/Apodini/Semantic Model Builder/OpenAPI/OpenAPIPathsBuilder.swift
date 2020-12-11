//
//  OpenAPIPathBuilder.swift
//  
//
//  Created by Lorena Schlesinger on 15.11.20.
//

import Vapor

struct OpenAPIPathBuilder: PathBuilder {
    private(set) var pathComponents: [Vapor.PathComponent] = []
    
    fileprivate var pathDescription: String {
        pathComponents
                .map { pathComponent in
                    pathComponent.description
                }
                .joined(separator: "/")
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
        pathComponents.append(.constant(pathComponent))
    }

    mutating func append<T>(_ parameter: Parameter<T>) {
        let pathComponent = parameter.description
        pathComponents.append(.parameter(pathComponent))
    }
}
