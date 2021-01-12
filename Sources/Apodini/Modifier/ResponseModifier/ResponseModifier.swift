//
//  ResponseModifier.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import Foundation


typealias LazyAnyResponseTransformer = () -> (AnyResponseTransformer)


struct ResponseTransformerContextKey: ContextKey {
    static var defaultValue: [LazyAnyResponseTransformer] = []
    
    static func reduce(value: inout [LazyAnyResponseTransformer], nextValue: () -> [LazyAnyResponseTransformer]) {
        value.append(contentsOf: nextValue())
    }
}

/// A `ResponseModifier` can be used to transform the output of `Handler`'s response to a different type using a `ResponseTransformer`
public struct ResponseModifier<H: Handler, T: ResponseTransformer>: HandlerModifier where H.Response.Content == T.InputContent {
    public typealias Response = Apodini.Response<T.Content>
    
    public let component: H
    let responseTransformer: () -> (T)
    
    
    init(_ component: H, responseTransformer: @escaping () -> (T)) {
        assertTypeIsStruct(T.self, messagePrefix: "ResponseModifier")
        self.component = component
        self.responseTransformer = responseTransformer
    }
}


extension ResponseModifier: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(ResponseTransformerContextKey.self, value: [responseTransformer], scope: .nextHandler)
        component.accept(visitor)
    }
}
