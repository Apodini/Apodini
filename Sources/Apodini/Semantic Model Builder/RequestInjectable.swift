//
//  RequestInjectable.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
@_implementationOnly import Runtime


protocol RequestInjectable {
    func inject(using request: Request) throws
}

protocol AnyParameter {
    func accept(_ visitor: AnyParameterVisitor)
}

extension AnyParameter {
    func accept(_ visitor: AnyParameterVisitor) {
        visitor.visit(self)
    }
}

protocol AnyParameterVisitor {
    func visit<P: AnyParameter>(_ parameter: P)

    func visit<Element>(_ parameter: Parameter<Element>)
}
extension AnyParameterVisitor {
    func visit<P: AnyParameter>(_ parameter: P) {}
    func visit<Element>(_ parameter: Parameter<Element>) {}
}

extension Handler {
    func extractParameters() -> [(String, AnyParameter)] {
        Apodini.extractParameters(from: self)
    }
}
extension AnyResponseTransformer {
    func extractParameters() -> [(String, AnyParameter)] {
        Apodini.extractParameters(from: self)
    }
}
