//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

protocol ComparableObject {
    typealias Result = ChangeContextNode

    func compare(to other: Self) -> Result
    func evaluate(result: Result) -> Change?
}

extension ComparableObject {

    func compare<P: ComparableProperty>(_ keyPath: KeyPath<Self, P>, with other: Self) -> P.Result {
        let ownProperty = self[keyPath: keyPath]
        let othersProperty = other[keyPath: keyPath]

        return ownProperty.compare(to: othersProperty)
    }

    func compare<O: ComparableObject>(_ keyPath: KeyPath<Self, O>, with other: Self) -> Self.Result {
        let ownProperty = self[keyPath: keyPath]
        let othersProperty = other[keyPath: keyPath]

        return ownProperty.compare(to: othersProperty)
    }
}

extension ComparableObject {

    func change(in node: Result) -> Result? {
        node.change(for: Self.self)
    }
}

extension ComparableObject {
    static var identifier: ObjectIdentifier {
        .init(Self.self)
    }
}
