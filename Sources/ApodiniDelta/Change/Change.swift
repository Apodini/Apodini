//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation

/// An abstract change
class Change: Codable {
    let location: String
    let changeType: ChangeType

    init(location: String, changeType: ChangeType) {
        self.location = location
        self.changeType = changeType
    }

    func isEqual(to other: Change) -> Bool {
        type(of: self) == type(of: other)
            && location == other.location
            && changeType == other.changeType
    }
    
    func change<C: _Comparable>(_ type: C.Type) -> Change? {
        if location == C.changeLocation {
            return self
        }
        return nil
    }
    
    func change<C: ComparableObject>(_ comparable: C) -> Change? {
        if location == comparable.deltaIdentifier.rawValue {
            return self
        }
        return nil
    }
}

// MARK: - Equatable
extension Change: Equatable {
    static func == (lhs: Change, rhs: Change) -> Bool {
        lhs.isEqual(to: rhs)
    }
}

// MARK: - Convenience
extension Change {
    static func valueChange<V: Value>(location: String, from: V, to: V) -> Change {
        ValueChange(location: location, from: from, to: to)
    }

    static func addChange<V: Value>(location: String, addedValue: V) -> Change {
        AddChange(location: location, addedValue: addedValue)
    }

    static func removeChange<V: Value>(location: String, removedValue: V) -> Change {
        RemoveChange(location: location, removedValue: removedValue)
    }

    static func compositeChange(location: String, changes: [Change]) -> Change {
        CompositeChange(location: location, changes: changes)
    }
}
