//
//  WebSocketPathBuilder.swift
//  
//
//  Created by Max Obermeier on 09.12.20.
//

import Foundation

struct WebSocketPathBuilder: PathBuilder {
    private var pathComponents: [String] = []
    
    
    var pathIdentifier: String {
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
        pathComponents.append(pathComponent)
    }
    
    mutating func append<T>(_ parameter: Parameter<T>) {
        let pathComponent = parameter.description
        pathComponents.append(pathComponent)
    }
}
