//
//  HTTPMethodModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor

struct HTTPMethodContextKey: ContextKey {
    static var defaultValue: Vapor.HTTPMethod = .GET
    
    static func reduce(value: inout Vapor.HTTPMethod, nextValue: () -> Vapor.HTTPMethod) {
        value = nextValue()
    }
}

public struct HTTPMethodModifier<ModifiedComponent: Component>: Modifier {
    let component: ModifiedComponent
    let httpMethod: Vapor.HTTPMethod
    
    
    init(_ component: ModifiedComponent, httpMethod: Vapor.HTTPMethod) {
        self.component = component
        self.httpMethod = httpMethod
    }
}


extension HTTPMethodModifier: Visitable {
    func visit(_ visitor: SynaxTreeVisitor) {
        visitor.addContext(HTTPMethodContextKey.self, value: httpMethod, scope: .environment)
        component.visit(visitor)
    }
}


extension Component {
    /// An `httpMethod` modifier can be used to explcitly specify the `HTTPMethod` that is used to send a request to a `Component`
    /// - Parameter httpMethod: The `HTTPMethod` that is used to send a request to a `Component`
    /// - Returns: The modified `Component` with a specified `HTTPMethod`
    public func httpMethod(_ httpMethod: Vapor.HTTPMethod) -> HTTPMethodModifier<Self> {
        HTTPMethodModifier(self, httpMethod: httpMethod)
    }
}
