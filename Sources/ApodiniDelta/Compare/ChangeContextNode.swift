//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

class ChangeContextNode {

    private(set) var changes: [ObjectIdentifier: Any] = [:]

    private var hasChanges: Bool { !changes.isEmpty }

    func register<P: ComparableProperty>(_ result: P.Result) {
        if result.isChange {
            precondition(changes[P.identifier] == nil, "Attempting to override changes of \(P.self).")
            changes[P.identifier] = result
        }
    }

    func register<O: ComparableObject>(_ result: O.Result, for type: O.Type) {
        if result.hasChanges {
            precondition(changes[O.identifier] == nil, "Attempting to override changes of \(type).")
            changes[O.identifier] = result
        }
    }

    func change<P: ComparableProperty>(for property: P.Type) -> P.Result? {
        changes[P.identifier] as? P.Result
    }

    func change<O: ComparableObject>(for object: O.Type) -> O.Result? {
        changes[O.identifier] as? O.Result
    }
}
