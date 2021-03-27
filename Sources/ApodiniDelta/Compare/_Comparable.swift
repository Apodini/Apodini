//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation

protocol ChangeContainable {
    var containsChange: Bool { get }
}

protocol _Comparable: Equatable {
    associatedtype Result: ChangeContainable

    var specifiedName: String? { get }

    func compare(to other: Self) -> Result
}

extension _Comparable {

    var specifiedName: String? { nil }

    var identifierName: String { specifiedName ?? String(describing: Self.self) }

    static var identifier: ObjectIdentifier { .init(Self.self) }

    func change(in node: ChangeContextNode) -> Result? {
        node.change(for: Self.self)
    }

}
