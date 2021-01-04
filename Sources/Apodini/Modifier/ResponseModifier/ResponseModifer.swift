//
//  ResponseModifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO


typealias LazyAnyResponseTransformer = () -> (AnyResponseTransformer)


struct ResponseContextKey: ContextKey {
    static var defaultValue: [LazyAnyResponseTransformer] = []
    
    static func reduce(value: inout [LazyAnyResponseTransformer], nextValue: () -> [LazyAnyResponseTransformer]) {
        value.append(contentsOf: nextValue())
    }
}


/// A `ResponseModifier` can be used to transform the output of `Handlers`'s response to a different type using a `ResponseTransformer`
/// by performing a transformation on the `Action` of the `Handlers`.
public struct ResponseModifier<H: Handler, T: ResponseTransformer>: HandlerModifier where H.Response.ResponseContent == T.Response {
    public typealias Response = T.TransformedResponse
    
    public let component: H
    let responseTransformer: () -> (T)
    
    
    init(_ component: H, responseTransformer: @escaping () -> (T)) {
        assertTypeIsStruct(T.self, messagePrefix: "ResponseTransformer")
        self.component = component
        self.responseTransformer = responseTransformer
    }
}


extension ResponseModifier: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(ResponseContextKey.self, value: [responseTransformer], scope: .nextHandler)
        component.accept(visitor)
    }
}
