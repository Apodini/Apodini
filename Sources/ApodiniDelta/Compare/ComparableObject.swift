//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

protocol ComparableObject: _Comparable {
    typealias Result = ChangeContextNode

    var deltaIdentifier: DeltaIdentifier { get }

    func evaluate(result: Result) -> Change?
}

extension ComparableObject {

    func compare<C: _Comparable>(_ keyPath: KeyPath<Self, C>, with other: Self) -> C.Result {
        let ownProperty = self[keyPath: keyPath]
        let othersProperty = other[keyPath: keyPath]

        return ownProperty.compare(to: othersProperty)
    }
}
