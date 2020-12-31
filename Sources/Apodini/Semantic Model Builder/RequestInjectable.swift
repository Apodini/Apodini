//
//  RequestInjectable.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
@_implementationOnly import Runtime


protocol RequestInjectable {
    mutating func inject(using request: Request) throws
    func accept(_ visitor: RequestInjectableVisitor)
}

extension RequestInjectable {
    func accept(_ visitor: RequestInjectableVisitor) {
        visitor.visit(self)
    }
}

protocol RequestInjectableVisitor {
    func visit<Injectable: RequestInjectable>(_ requestInjectable: Injectable)

    func visit<Element>(_ parameter: Parameter<Element>)
}
extension RequestInjectableVisitor {
    func visit<Injectable: RequestInjectable>(_ requestInjectable: Injectable) {}
    func visit<Element>(_ parameter: Parameter<Element>) {}
}

extension Handler {
    func extractRequestInjectables() -> [String: RequestInjectable] {
        Apodini.extractRequestInjectables(from: self)
    }
}
extension AnyResponseTransformer {
    func extractRequestInjectables() -> [String: RequestInjectable] {
        Apodini.extractRequestInjectables(from: self)
    }
}
