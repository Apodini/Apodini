//
//  PathComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Foundation


public protocol PathComponent {
    func append<P: PathBuilder>(to pathBuilder: inout P)
}

public protocol PathBuilder {
    mutating func append(_ string: String)
    mutating func append<T>(_ identifiier: Identifier<T>)
}


extension String: PathComponent {
    public func append<P>(to pathBuilder: inout P) where P : PathBuilder {
        pathBuilder.append(self)
    }
}


public struct Identifier<T: Identifiable>: PathComponent {
    let identifier: String
    
    public init(_ type: T.Type = T.self) {
        let typeName = String(describing: T.self).uppercased()
        identifier = "\(typeName)-\(UUID())"
    }
    
    public func append<P>(to pathBuilder: inout P) where P : PathBuilder {
        pathBuilder.append(self)
    }
}
