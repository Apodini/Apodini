//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

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
