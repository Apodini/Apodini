//
//  ResponseModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor


public protocol ResponseMediator: ResponseEncodable {
    associatedtype Response
    
    
    init(_ response: Response)
}


public struct ResponseContextKey: ContextKey {
    public static var defaultValue: ResponseEncodable.Type = Never.self
    
    public static func reduce(value: inout ResponseEncodable.Type, nextValue: () -> ResponseEncodable.Type) {
        value = nextValue()
    }
}


public struct ResponseModifier<C: Component, M: ResponseMediator>: Modifier where M.Response == C.Response {
    let component: C
    let mediator = M.self
    
    
    init(_ component: C, mediator: M.Type) {
        self.component = component
    }
    
    
    public func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.addContext(ResponseContextKey.self, value: M.self, scope: .nextComponent)
        component.visit(&visitor)
    }
    
    public func handle(_ request: Request) -> EventLoopFuture<M> {
        component.handleInContext(of: request)
            .map { response in
                M(response)
            }
    }
}


extension Component {
    public func response<M: ResponseMediator>(_ modifier: M.Type) -> ResponseModifier<Self, M> where Self.Response == M.Response {
        ResponseModifier(self, mediator: M.self)
    }
}
