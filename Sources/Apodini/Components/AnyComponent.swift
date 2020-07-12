//
//  AnyComponent.swift
//  
//
//  Created by Paul Schmiedmayer on 7/10/20.
//

import Vapor


public struct AnyComponent: Component {
    private let _visit: (_ visitor: Visitor) -> ()
    
    
    init<C: Component>(_ component: C) {
        self._visit = component.visit
    }
}


extension AnyComponent: Visitable {
    func visit(_ visitor: Visitor) {
        _visit(visitor)
    }
}
