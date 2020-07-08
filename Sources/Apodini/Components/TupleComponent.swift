//
//  TupleComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


public struct TupleComponent<T>: _Component {
    private let tuple: T
    

    init(_ tuple: T) {
        self.tuple = tuple
    }
    
    
    public func visit<V>(_ visitor: inout V) where V: Visitor {
        for child in Mirror(reflecting: tuple).children {
            guard let visitableComponent = child.value as? Visitable else {
                fatalError("TupleComponent must contain a tuple of Components")
            }
            
            visitableComponent.visit(&visitor)
        }
    }
}
