//
//  ResponseModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor


public protocol AnyResponseTransformer {
    var transformedResponseType: ResponseEncodable.Type { get }
    
    func transform(response: ResponseEncodable) -> ResponseEncodable
}


public protocol ResponseTransformer: AnyResponseTransformer {
    associatedtype Response
    associatedtype TransformedResponse: ResponseEncodable
    
    
    func transform(response: Self.Response) -> TransformedResponse
}


extension ResponseTransformer {
    public var transformedResponseType: ResponseEncodable.Type {
        Self.TransformedResponse.self
    }
    
    public func transform(response: ResponseEncodable) -> ResponseEncodable {
        guard let response = response as? Self.Response else {
            fatalError("Coult not cast the `ResponseEncodable` passed to the `AnyResponseTransformer` to the expected \(Response.self) type")
        }
        return self.transform(response: response)
    }
}


struct ResponseContextKey: ContextKey {
    static var defaultValue: [() -> (AnyResponseTransformer)] = []
    
    static func reduce(value: inout [() -> (AnyResponseTransformer)], nextValue: () -> [() -> (AnyResponseTransformer)]) {
        value.append(contentsOf: nextValue())
    }
}


public struct ResponseModifier<C: Component, T: ResponseTransformer>: Modifier where T.Response == C.Response {    
    public typealias Response = T.TransformedResponse
    
    let component: C
    let responseTransformer: () -> (T)
    
    
    init(_ component: C, responseTransformer: @escaping () -> (T)) {
        self.component = component
        self.responseTransformer = responseTransformer
    }
    
    
    public func handle() -> Self.Response {
        fatalError("A Modifier's handle method should never be called!")
    }
}


extension ResponseModifier: Visitable {
    func visit(_ visitor: Visitor) {
        visitor.addContext(ResponseContextKey.self, value: [responseTransformer], scope: .nextComponent)
        component.visit(visitor)
    }
}

extension Component {
    public func response<T: ResponseTransformer>(_ responseTransformer: @escaping @autoclosure () -> (T)) -> ResponseModifier<Self, T> where Self.Response == T.Response {
        ResponseModifier(self, responseTransformer: responseTransformer)
    }
}
