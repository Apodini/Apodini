//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
@_implementationOnly import AssociatedTypeRequirementsVisitor


/// Utility functions for testing arbitrary objects for equality.
public enum AnyEquatable {
    /// The result of an equality comparison of two objects of unknown types.
    public enum ComparisonResult {
        /// Both objects are of the same type, which conforms to `Equatable`, and the comparison returned `true`.
        case equal
        /// Both objects are of the same type, which conforms to `Equatable`, and the comparison returned `false`.
        case notEqual
        /// Both objects are of the same type, but that type does not conform to `Equatable`, meaning we cannot compare the objects.
        case notEquatable
        /// The objects are of different types, meaning they cannot be compared.
        case nonMatchingTypes
        
        /// Whether the objects were equal.
        /// - Note: This property being `true` implies that the objects were of the same type, and that that type conforms to `Equatable`.
        public var isEqual: Bool { self == .equal }
        
        /// Whether two objects were not equal.
        /// - Note: This property being `true` implies that the objects were of the same type, and that that type conforms to `Equatable`.
        public var isNotEqual: Bool { self == .notEqual }
    }
    
    
    /// Checks whether the two objects of unknown types are equal.
    /// - Returns: `true` if both objects are `Equatable`, of the same type, and `lhs == rhs`,
    ///            `false` if both objects are `Equatable`, of the same type, and `self.value != other.value`,
    ///             `nil` if the two objects are not `Equatable`, or not of the same type.
    public static func compare(_ lhs: Any, _ rhs: Any) -> ComparisonResult {
        switch TestEqualsImpl(lhs)(rhs) {
        case .some(let result):
            return result
        case .none:
            // If the visitor returns nil, it was unable to visit the type, meaning `lhs` is not Equatable.
            return .notEquatable
        }
    }
    
    
    private struct TestEqualsImpl: EquatableVisitor {
        let value1: Any
        
        init(_ value1: Any) {
            self.value1 = value1
        }
        
        func callAsFunction<T: Equatable>(_ value2: T) -> ComparisonResult {
            if let value1 = value1 as? T {
                precondition(type(of: value1) == type(of: value2))
                return value1 == value2 ? .equal : .notEqual
            } else {
                return .nonMatchingTypes
            }
        }
    }
}
