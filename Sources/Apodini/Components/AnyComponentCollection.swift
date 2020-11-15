//
//  TupleComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


public struct AnyComponentCollection: ComponentCollection {
    private let components: [AnyComponent]
    
    
    init(_ components: [AnyComponent]) {
        self.components = components
    }
    
    init(_ components: AnyComponent...) {
        self.components = components
    }
}


extension AnyComponentCollection: Visitable {
    func visit(_ visitor: SynaxTreeVisitor) {
        for component in components {
            visitor.enter(collection: self)
            component.visit(visitor)
            visitor.exit(collection: self)
        }
    }
}
