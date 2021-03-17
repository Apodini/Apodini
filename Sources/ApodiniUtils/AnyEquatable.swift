//
//  AnyEquatable.swift
//  
//
//  Created by Lukas Kollmer on 2021-03-17.
//

// swiftlint:disable discouraged_optional_boolean

import Foundation
@_implementationOnly import AssociatedTypeRequirementsVisitor


/// The `AnyEquatable` type acts as a wrapper around an `Any ` value,
/// which can then be compared to another `AnyEquatable` object using the `equals` function.
/// - Note: This will only work if the underlying value does in fact conform to the `Equatable` protocol.
public struct AnyEquatable {
    /// The underlying type-erased value
    public let value: Any
    
    /// Constructs a new `AnyEquatable` from some type-erased value.
    public init(_ value: Any) {
        self.value = value
    }
    
    /// Checks whether the two wrapped objects are equal.
    /// - Returns: `true` if both objects are `Equatable`, of the same type, and `self.value == other.value`,
    ///            `false` if both objects are `Equatable`, of the same type, and `self.value != other.value`,
    ///             `nil` if the two objects are not `Equatable`, or not of the same type.
    public func equals(_ other: AnyEquatable) -> Bool? {
        if case let .some(.some(result)) = TestEqualsImpl(other: other.value)(self.value) {
            return result
        } else {
            return nil
        }
    }
    
    
    private struct TestEqualsImpl: EquatableVisitor {
        let other: Any
        
        func callAsFunction<T: Equatable>(_ value: T) -> Bool? {
            if let other = other as? T {
                precondition(type(of: value) == type(of: other))
                return value == other
            } else {
                return false
            }
        }
    }
}
