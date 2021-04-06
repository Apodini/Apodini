//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

/// The result of comparing two comparables
enum ComparisonResult<C: _Comparable> {
    typealias Element = C

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
    /// The corresponding change object of the comparison result
    var change: Change? {
        let changeLocation = Element.changeLocation
        switch self {
        case .equal: return nil
        case let .added(addedValue): return .addChange(location: changeLocation, addedValue: addedValue)
        case let .changed(from, to): return .valueChange(location: changeLocation, from: from, to: to)
        case let .removed(removedValue): return .removeChange(location: changeLocation, removedValue: removedValue)
        }
    }
}
