//
//  PathComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

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
    public func append<P>(to pathBuilder: inout P) where P : PathBuilder {
        pathBuilder.append(self)
    }
}
