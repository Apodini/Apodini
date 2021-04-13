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

/// Base protocol that all comparable objects or simple properties conform to
protocol _Comparable: Value {
    /// The result out of the comparison
    associatedtype Result: ChangeContainable

    /// Specifies the logic of comparing with another comparable
    /// - Parameters:
    ///     - other: Other comparable
    /// - Returns: Comparison result
    func compare(to other: Self) -> Result
}

extension _Comparable {
    /// An optional name that can be specified on the type,
    /// that will be used as `location` when a change occurs
    static var specifiedName: String? { nil }

    /// Name of the change location. Returns `specifiedName` if provided, or `typeName` by default
    static var changeLocation: String { specifiedName ?? typeName }
}
