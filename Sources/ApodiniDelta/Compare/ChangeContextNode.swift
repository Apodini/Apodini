//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

class ChangeContextNode {

    private(set) var changes: [ObjectIdentifier: Any] = [:]

    func register<C: _Comparable>(_ result: C.Result, for type: C.Type = C.self) {
        if result.containsChange {
            precondition(changes[C.identifier] == nil, "Attempting to override changes of \(type).")
            changes[C.identifier] = result
        }
    }

    func change<C: _Comparable>(for comparable: C.Type) -> C.Result? {
        changes[C.identifier] as? C.Result
    }

    func register<C: ComparableObject>(_ node: CollectionChangeContextNode<C>) {
        if node.containsChange {
            precondition(changes[C.identifier] == nil, "Attempting to override changes of \(C.self).")
            changes[C.identifier] = node
        }
    }

    func collectionChangeContextNode<C: ComparableObject>(for comparableObject: C.Type) -> CollectionChangeContextNode<C>? {
        changes[C.identifier] as? CollectionChangeContextNode<C>
    }

}

extension ChangeContextNode: ChangeContainable {

    var containsChange: Bool { !changes.isEmpty }

}
