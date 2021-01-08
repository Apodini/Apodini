//
//  WebSocketPathBuilder.swift
//  
//
//  Created by Max Obermeier on 09.12.20.
//

struct WebSocketPathBuilder: PathBuilderWithResult {
    private var path: [String] = []
    
    mutating func append(_ string: String) {
        path.append(string.lowercased())
    }

    mutating func append<Type>(_ parameter: EndpointPathParameter<Type>) {
        path.append(":\(parameter.name):")
    }

    func result() -> String {
        path.joined(separator: ".")
    }
}
