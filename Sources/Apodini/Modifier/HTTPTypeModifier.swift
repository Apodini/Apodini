//
//  HTTPTypeModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO


public struct HTTPTypeModifier<ModifiedComponent: Component>: Modifier {
    let component: ModifiedComponent
    let httpType: HTTPType
    
    
    init(_ component: ModifiedComponent, httpType: HTTPType) {
        self.component = component
        self.httpType = httpType
    }
    
    
    public func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.addContext(label: "httpType", httpType)
        component.visit(&visitor)
    }
}


extension Component {
    public func httpType(_ httpType: HTTPType) -> HTTPTypeModifier<Self> {
        HTTPTypeModifier(self, httpType: httpType)
    }
}
