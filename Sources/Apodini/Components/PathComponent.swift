//
//  PathComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Foundation


public protocol PathComponent {
    
}

protocol _PathComponent: PathComponent {
    func append<P: PathBuilder>(to pathBuilder: inout P)
}

protocol PathBuilder {
    mutating func append(_ string: String)
    mutating func append<T>(_ identifiier: Identifier<T>)
}


extension String: _PathComponent {
    func append<P>(to pathBuilder: inout P) where P : PathBuilder {
        pathBuilder.append(self)
    }
}


public struct Identifier<T: Identifiable> {
    let identifier: String
    
    public init(_ type: T.Type = T.self) {
        let typeName = String(describing: T.self).uppercased()
        identifier = "\(typeName)-\(UUID())"
    }
}

extension Identifier: _PathComponent {
    func append<P>(to pathBuilder: inout P) where P : PathBuilder {
        pathBuilder.append(self)
    }
}
