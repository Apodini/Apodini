//
//  Visitor.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

public protocol Visitor {
    mutating func enter<C: Component>(_ component: C)
    mutating func addContext<P: CustomStringConvertible>(label: String?, _ property: P)
    mutating func register<C: Component>(_ component: C)
    mutating func exit<C: Component>(_ component: C)
}


public protocol Visitable {
    func visit<V: Visitor>(_ visitor: inout V)
}
