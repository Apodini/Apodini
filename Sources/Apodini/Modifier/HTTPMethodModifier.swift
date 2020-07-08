//
//  HTTPMethodModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor

public struct HTTPMethodContextKey: ContextKey {
    public static var defaultValue: Vapor.HTTPMethod = .GET
    
    public static func reduce(value: inout Vapor.HTTPMethod, nextValue: () -> Vapor.HTTPMethod) {
        value = nextValue()
    }
}

public struct HTTPMethodModifier<ModifiedComponent: Component>: _Modifier {
    let component: ModifiedComponent
    let httpMethod: Vapor.HTTPMethod
    
    
    init(_ component: ModifiedComponent, httpMethod: Vapor.HTTPMethod) {
        self.component = component
        self.httpMethod = httpMethod
    }
    
    
    func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.addContext(HTTPMethodContextKey.self, value: httpMethod, scope: .environment)
        if let visitableComponent = component as? Visitable {
            visitableComponent.visit(&visitor)
        }
    }
}


extension Component {
    public func httpMethod(_ httpMethod: Vapor.HTTPMethod) -> HTTPMethodModifier<Self> {
        HTTPMethodModifier(self, httpMethod: httpMethod)
    }
}
