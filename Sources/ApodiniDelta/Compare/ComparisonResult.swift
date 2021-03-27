//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

enum ComparisonResult<V: Value> {
    typealias Element = V

    case equal

    case added(Element)
    case changed(from: Element, to: Element)
    case removed(Element)
}

extension ComparisonResult: ChangeContainable {

    var containsChange: Bool {
        if case .equal = self {
            return false
        }
        return true
    }
}

extension ComparisonResult {

    var change: Change? {
        let changeLocation = String(describing: Element.self)
        switch self {
        case .equal: return nil
        case .added(let addedValue): return AddChange(location: changeLocation, addedValue: addedValue.description)
        case .changed(from: let from, to: let to): return ValueChange(location: changeLocation, from: from.description, to: to.description)
        case .removed(let removedValue): return RemoveChange(location: changeLocation, removedValue: removedValue.description)
        }
    }
}
