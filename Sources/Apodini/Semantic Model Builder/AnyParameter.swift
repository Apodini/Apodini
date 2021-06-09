//
//  AnyParameter.swift
//  
//
//  Created by Max Obermeier on 20.05.21.
//

import Foundation

protocol AnyParameter {
    var options: PropertyOptionSet<ParameterOptionNameSpace> { get set }
    
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
