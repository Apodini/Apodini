//
//  ResponseModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor


public protocol AnyResponseMediator {
    init(_ response: ResponseEncodable)
}


public protocol ResponseMediator: AnyResponseMediator, ResponseEncodable {
    associatedtype Response
    
    
    init(_ response: Self.Response)
}


extension ResponseMediator {
    public init(_ response: ResponseEncodable) {
        guard let response = response as? Self.Response else {
            fatalError("Coult not cast the `ResponseEncodable` passed to the `AnyResponseMediator` to the expected \(Response.self) type")
        }
        self.init(response)
    }
}


struct ResponseContextKey: ContextKey {
    static var defaultValue: [AnyResponseMediator.Type] = []
    
    static func reduce(value: inout [AnyResponseMediator.Type], nextValue: () -> [AnyResponseMediator.Type]) {
        value.append(contentsOf: nextValue())
    }
}


public struct ResponseModifier<C: Component, M: ResponseMediator>: Modifier where M.Response == C.Response {    
    public typealias Response = M
    
    let component: C
    let mediator = M.self
    
    
    init(_ component: C, mediator: M.Type) {
        self.component = component
    }
    
    
    public func handle() -> Self.Response {
        fatalError("A Modifier's handle method should never be called!")
    }
}


extension ResponseModifier: Visitable {
    func visit(_ visitor: Visitor) {
        visitor.addContext(ResponseContextKey.self, value: [M.self], scope: .nextComponent)
        component.visit(visitor)
    }
}

extension Component {
    public func response<M: ResponseMediator>(_ modifier: M.Type) -> ResponseModifier<Self, M> where Self.Response == M.Response {
        ResponseModifier(self, mediator: M.self)
    }
}
