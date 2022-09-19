//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation


extension Equatable {
    fileprivate func comparesEqual(with other: Any) -> Bool? {
        if let other = other as? Self {
            return self == other
        } else {
            return nil
        }
    }
}


/// Utility functions for testing arbitrary objects for equality.
public enum AnyEquatable {
    /// The result of an equality comparison of two objects of unknown types.
    public enum ComparisonResult {
        /// Both objects are of the same type, which conforms to `Equatable`, and the comparison returned `true`.
        case equal
        /// Both objects are of the same type, which conforms to `Equatable`, and the comparison returned `false`.
        case notEqual
        /// The objects may or may not be of the same type, but at least one of the objects is of a type which does not conform to `Equatable`.
        case inputNotEquatable
        
        /// Whether the objects were equal.
        /// - Note: This property being `true` implies that the objects were of the same type, and that that type conforms to `Equatable`.
        public var isEqual: Bool { self == .equal }
        
        /// Whether two objects were not equal.
        /// - Note: This property being `true` implies that the objects were of the same type, and that that type conforms to `Equatable`.
        public var isNotEqual: Bool { self == .notEqual }
    }
    
    
    /// Checks whether the two objects of unknown types are equal.
    /// - Returns: Returns a according ``ComparisonResult``.
    public static func compare(_ lhs: Any, _ rhs: Any) -> ComparisonResult {
        guard let lhsEq = lhs as? any Equatable else {
            return .inputNotEquatable
        }
        switch lhsEq.comparesEqual(with: rhs) {
        case nil:
            return .inputNotEquatable
        case .some(true):
            return .equal
        case .some(false):
            return .notEqual
        }
    }
}
