//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

/// Base protocol that all comparable properties (such as strings, integers etc.) conform to
protocol ComparableProperty: _Comparable {
    typealias Result = ComparisonResult<Self>
}

extension ComparableProperty {
    func compare(to other: Self) -> Result {
        self == other ? .equal : .changed(from: self, to: other)
    }
}

extension ComparableProperty {
    func change(in node: ChangeContextNode) -> Change? {
        node.change(for: Self.self)?.change
    }
}
