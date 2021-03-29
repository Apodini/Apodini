//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

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

    var change: Change? {
        let changeLocation = Element.changeLocation
        switch self {
        case .equal: return nil
        case .added(let addedValue): return .addChange(location: changeLocation, addedValue: addedValue)
        case .changed(from: let from, to: let to): return .valueChange(location: changeLocation, from: from, to: to)
        case .removed(let removedValue): return .removeChange(location: changeLocation, removedValue: removedValue)
        }
    }
}
