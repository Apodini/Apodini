//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation


/// A type erasure for the `PropertyOptionKey`
public class AnyPropertyOptionKey: Equatable, Hashable {
    /// Combines two `PropertyOptionKey`s.
    /// - Parameters:
    ///   - lhs: The left hand side `PropertyOptionKey` that should be combined
    ///   - rhs: The left hand side `PropertyOptionKey` that should be combined
    /// - Returns: The combined `PropertyOptionKey`
    func combine(lhs: Any, rhs: Any) -> Any {
        fatalError("AnyPropertyOptionKey.combine should be overridden!")
    }

    public static func == (lhs: AnyPropertyOptionKey, rhs: AnyPropertyOptionKey) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    var propertyOptionType: String {
        fatalError("AnyPropertyOptionKey.propertyOptionType not implemented!")
    }
}


/// A `PropertyOptionKey` can be associated with a `PropertyNameSpace` and and store an `Option` that is associated with the `PropertyOptionKey` within the `PropertyNameSpace`.
public class PropertyOptionKey<PropertyNameSpace, Option: PropertyOption>: AnyPropertyOptionKey {
    override var propertyOptionType: String {
        let test = String(describing: Option.self)
        return test
    }
    
    /// Initialize an empty `PropertyOptionKey`
    override public init() {}

    override func combine(lhs: Any, rhs: Any) -> Any {
        guard let lhs = lhs as? Option, let rhs = rhs as? Option else {
            preconditionFailure("Both sides of the `&` have to conform to \(Option.self)")
        }
        
        return lhs & rhs
    }
}
