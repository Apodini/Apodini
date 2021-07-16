//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// A protocol for identifying `Optional`s.
public protocol OptionalProtocol {
    /// The underlying type of the Optional.
    associatedtype Wrapped
    // Disabling syntactic_sugar, improves readability and showcases what really happens here.
    // swiftlint:disable:next syntactic_sugar missing_docs
    var optionalInstance: Optional<Wrapped> { get }
}


extension Optional: OptionalProtocol {
    // Disabling syntactic_sugar, improves readability and showcases what really happens here.
    // swiftlint:disable:next syntactic_sugar
    public var optionalInstance: Optional<Wrapped> { self }
}


/// Check whether `value` is some optional and is `nil`
public func isNil(_ value: Any) -> Bool {
    switch value {
    case Optional<Any>.none:
        return true
    default:
        return false
    }
}
