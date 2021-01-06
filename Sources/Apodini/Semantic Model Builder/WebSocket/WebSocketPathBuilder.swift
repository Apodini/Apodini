//
//  WebSocketPathBuilder.swift
//  
//
//  Created by Max Obermeier on 09.12.20.
//

struct WebSocketPathBuilder: PathBuilder {
    private var path: [String] = []
    var pathIdentifier: String {
        path.joined(separator: ".")
    }
    
    init(_ path: [EndpointPath]) {
        path.acceptAll(&self)
    }
    
    mutating func append(_ string: String) {
        path.append(string.lowercased())
    }

    mutating func append<Type>(_ parameter: EndpointPathParameter<Type>) {
        path.append(":\(parameter.name):")
    }
}
