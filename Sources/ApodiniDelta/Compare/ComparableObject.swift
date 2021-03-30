//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

/// Base protocol that all comparable objects conform to
protocol ComparableObject: _Comparable {
    typealias Result = ChangeContextNode

    var deltaIdentifier: DeltaIdentifier { get }

    func evaluate(result: Result, embeddedInCollection: Bool) -> Change?
}

extension ComparableObject {
    /// Convenience default implementations by comparing properties with keypaths
    func compare<C: _Comparable>(_ keyPath: KeyPath<Self, C>, with other: Self) -> C.Result {
        let ownProperty = self[keyPath: keyPath]
        let othersProperty = other[keyPath: keyPath]

        return ownProperty.compare(to: othersProperty)
    }

    /**
     This functions can be removed if the type checking for ComparableCollection would work as expected
     */

    /// Convenience default implementations by comparing collection properties with keypaths
    func compare<C: Collection, O: ComparableObject>(_ keyPath: KeyPath<Self, C>, with other: Self) -> C.Result where C.Element == O {
        let ownProperty = self[keyPath: keyPath]
        let othersProperty = other[keyPath: keyPath]

        return ownProperty.compare(to: othersProperty)
    }
}
