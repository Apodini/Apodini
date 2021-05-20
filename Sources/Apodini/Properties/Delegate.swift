//
//  Delegate.swift
//  
//
//  Created by Max Obermeier on 17.05.21.
//

import Foundation

/// A `Delegate` is a lazy version of `DynamicProperty`. That is, your delegate `D` can wrap
/// multiple `Property`s and their functionality is maintained. The `Delegate` type makes its wrapped
/// instance of `D` discoverable to the Apodini runtime framework. Moreover, it delays initialization and verification
/// of `@Parameter`s to the point where you call `Delegate` as a function. This enables you to decode
/// input lazily and to do manual error handling in case decoding fails.
/// - Warning: `D` must be a `struct`
public struct Delegate<D> {
    // swiftlint:disable:next weak_delegate
    var delegate: D
    
    var connection = Environment(\.connection)
    
    let optionality: Optionality
    
    /// Create a `Delegate` from the given struct `delegate`.
    /// - Parameter `delegate`: the wrapped instance
    /// - Parameter `optionality`: the `Optionality` for all `@Parameter`s of the `delegate`
    public init(_ delegate: D, _ optionality: Optionality = .optional) {
        self.delegate = delegate
        self.optionality = optionality
    }
    
    /// Prepare the wrapped delegate `D` for usage.
    public func callAsFunction() throws -> D {
        try connection.wrappedValue.request.enterRequestContext(with: delegate) { _ in Void() }
        return delegate
    }
}

/// A generic `PropertyOption` that indicates if the `@Parameter` decoded and validated at all times. Setting this option won't
/// affect runtime behavior. The option allows for customizing documentation where Apodini cannot automatically determine if an
/// `@Parameter` will actually be decoded.
/// - Note: This type is only to be used on `Delegate`.
public enum Optionality: PropertyOption {
    /// Default for `@Parameter`s behind a `Delegate`. Documentation should show this parameter as not required.
    case optional
    /// Default for normal `@Parameter`s, i.e. such that are not behind a `Delegate`. Pass this to a `Delegate`, if there is no path
    /// throgh your `handle()` that doesn't `throw` where the `Delegate` is not called.
    case required
}

extension PropertyOptionKey where PropertyNameSpace == ParameterOptionNameSpace, Option == Optionality {
    /// The key for `Optionality` of a `Parameter`
    public static let optionality = PropertyOptionKey<ParameterOptionNameSpace, Optionality>()
}
