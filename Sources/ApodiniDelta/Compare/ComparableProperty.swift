//
//  File.swift
//  
//
//  Created by Eldi Cano on 26.03.21.
//

import Foundation

protocol ComparableProperty: Equatable {
    typealias Result = ComparisonResult<Self>

    func compare(to other: Self) -> Result
}

extension ComparableProperty {

    func compare(to other: Self) -> Result {
        self == other ? .equal : .changed(from: self, to: other)
    }
}

extension ComparableProperty {

    func change(in node: ChangeContextNode) -> Result? {
        node.change(for: Self.self)
    }
}

extension ComparableProperty {

    static var identifier: ObjectIdentifier {
        .init(Self.self)
    }
}
