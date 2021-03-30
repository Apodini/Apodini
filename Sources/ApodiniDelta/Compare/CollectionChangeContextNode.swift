//
//  File.swift
//  
//
//  Created by Eldi Cano on 28.03.21.
//

import Foundation

/// A context node that holds the changes between two collections (additions, removals and changes)
class CollectionChangeContextNode<C: ComparableObject> {
    private(set) var additionsAndRemovals: [DeltaIdentifier: ComparisonResult<C>] = [:]
    private(set) var changes: [DeltaIdentifier: ChangeContextNode] = [:]

    var allDeltaIdentifiers: Set<DeltaIdentifier> {
        (Array(additionsAndRemovals.keys) + changes.keys).unique()
    }

    func register(_ node: ChangeContextNode, for identifier: DeltaIdentifier) {
        if node.containsChange {
            precondition(changes[identifier] == nil, "Attempting to override changes of \(C.self) with identifier: \(identifier.description)")
            changes[identifier] = node
        }
    }

    func register(_ result: ComparisonResult<C>, for identifier: DeltaIdentifier) {
        if result.containsChange {
            precondition(additionsAndRemovals[identifier] == nil, "Attempting to override changes of \(C.self) with identifier: \(identifier.description)")
            additionsAndRemovals[identifier] = result
        }
    }

    func change(for identifier: DeltaIdentifier) -> ChangeContainable? {
        additionsAndRemovals[identifier] ?? changes[identifier]
    }
}

extension CollectionChangeContextNode: ChangeContainable {
    var containsChange: Bool {
        !allDeltaIdentifiers.isEmpty
    }
}
