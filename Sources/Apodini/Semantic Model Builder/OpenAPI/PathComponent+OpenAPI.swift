//
//  PathComponent+OpenAPI.swift
//  
//
//  Created by Lorena Schlesinger on 10.12.20.
//

import OpenAPIKit

struct OpenAPIPathBuilder: PathBuilder {
    public lazy var path: OpenAPI.Path = OpenAPI.Path(stringLiteral: self.components.joined(separator: "/"))
    var components: [String] = []
    let parameters: [EndpointParameter]

    init(_ pathComponents: [_PathComponent], parameters: [EndpointParameter]) {
        self.parameters = parameters
        for pathComponent in pathComponents {
            pathComponent.append(to: &self)
        }
    }

    mutating func append<T>(_ parameter: Parameter<T>) {
        guard let p = parameters.first(where:
        { $0.id == parameter.id }) else {
            fatalError("Path contains parameter which cannot be found in endpoint's parameters.")
        }
        components.append("{\(p.name ?? p.label)}")
    }

    mutating func append(_ string: String) {
        components.append(string)
    }
}