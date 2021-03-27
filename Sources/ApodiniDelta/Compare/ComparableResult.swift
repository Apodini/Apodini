//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

enum ComparisonResult<C: Equatable> {
    typealias Element = C

    case equal
    case changed(from: Element, to: Element) // TODO add other change types, (added, removed)

    var isChange: Bool {
        if case .equal = self {
            return false
        }
        return true
    }
}

extension ComparisonResult where Element: CustomStringConvertible {

    var valueChange: ValueChange? {
        if case let .changed(from, to) = self {
            return .init(location: String(describing: Element.self), from: from.description, to: to.description)
        }
        return nil
    }
}
