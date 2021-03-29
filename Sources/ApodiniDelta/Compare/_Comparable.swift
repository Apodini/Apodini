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

protocol _Comparable: Value {
    associatedtype Result: ChangeContainable

    static var specifiedName: String? { get }

    func compare(to other: Self) -> Result
}

extension _Comparable {

    static var typeName: String { String(describing: Self.self) }

    var description: String { Self.typeName }

    static var specifiedName: String? { nil }

    static var changeLocation: String { specifiedName ?? typeName }

    static var identifier: ObjectIdentifier { .init(Self.self) }

}
