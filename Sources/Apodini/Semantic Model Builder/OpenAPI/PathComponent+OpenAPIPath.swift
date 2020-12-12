//
//  File.swift
//  
//
//  Created by Lorena Schlesinger on 10.12.20.
//

extension Array where Element == _PathComponent {
    func joinPathComponentsToOpenAPIPath(separator: String = "/") -> String {
        self.map(\.openAPIDescription).joined(separator: separator)
    }
    
}

extension _PathComponent {
    var openAPIDescription: String {
        switch self.description.first {
        case ":":
            return "{\(self.description.split(separator: ":")[0])}"
        default:
            return self.description
        }
    }
}
