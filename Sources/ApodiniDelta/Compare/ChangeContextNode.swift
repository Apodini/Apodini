//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

/// A context node that hold all changes during comparison of two comparables
class ChangeContextNode {
    /// Dictionary holding the changes of a specific comparable object
    private(set) var changes: [ObjectIdentifier: ChangeContainable] = [:]

    /// Used to register the result of comparison between two comparable objects
    func register<C: _Comparable>(_ result: C.Result, for type: C.Type = C.self) {
        if result.containsChange {
            precondition(changes[C.identifier] == nil, "Attempting to override changes of \(type).")
            changes[C.identifier] = result
        }
    }

    /// Change retrieval for a specific comparable type
    func change<C: _Comparable>(for comparable: C.Type) -> C.Result? {
        changes[C.identifier] as? C.Result
    }

    /**
     These functions can be removed if the type checking for ComparableCollection would work as expected
     */

    /// Used to register the result of comparison between two collections of comparable objects
    /// - Parameters:
    ///   - result: result of comparison
    ///   - type: The type of the `Element` of the collection
    func register<O: ComparableObject>(result: CollectionChangeContextNode<O>, for type: O.Type = O.self) {
        if result.containsChange {
            precondition(changes[O.identifier] == nil, "Attempting to override changes of \(type).")
            changes[O.identifier] = result
        }
    }

    /// Collection change retrieval for a specific type
    func change<O: ComparableObject>(comparable: O.Type) -> CollectionChangeContextNode<O>? {
        changes[O.identifier] as? CollectionChangeContextNode<O>
    }
}

// MARK: - ChangeContainable
extension ChangeContextNode: ChangeContainable {
    var containsChange: Bool { !changes.isEmpty }
}
