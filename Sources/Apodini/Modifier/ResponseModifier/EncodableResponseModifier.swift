//
//  EncodableResponseModifier.swift
//  
//
//  Created by Paul Schmiedmayer on 1/4/21.
//

import Foundation

/// A `EncodableResponseModifier` can be used to transform the output of `Handler`'s response to a different type using a `EncodableResponseTransformer`
public struct EncodableResponseModifier<H: Handler, T: EncodableResponseTransformer>: HandlerModifier where H.Response.ResponseContent == T.Response {
    public typealias Response = Action<T.TransformedResponse>
    
    public let component: H
    let responseTransformer: () -> (T)
    
    
    init(_ component: H, responseTransformer: @escaping () -> (T)) {
        assertTypeIsStruct(T.self, messagePrefix: "EncodableResponseModifier")
        self.component = component
        self.responseTransformer = responseTransformer
    }
}


extension EncodableResponseModifier: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(ResponseContextKey.self, value: [responseTransformer], scope: .nextHandler)
        component.accept(visitor)
    }
}
