//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

protocol AnyParameter {
    var options: PropertyOptionSet<ParameterOptionNameSpace> { get set }
    
    func accept(_ visitor: any AnyParameterVisitor)
}

extension AnyParameter {
    func accept(_ visitor: any AnyParameterVisitor) {
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
    func extractParameters() -> [(String, any AnyParameter)] {
        Apodini.extractParameters(from: self)
    }
}
