//
//  Delegate.swift
//  
//
//  Created by Max Obermeier on 17.05.21.
//

import Foundation

public struct Delegate<D> {
    
    var delegate: D
    
    var connection = Environment(\.connection)
    
    let optionality: Optionality
    
    public init(_ delegate: D, _ optionality: Optionality = .optional) {
        self.delegate = delegate
        self.optionality = optionality
    }
    
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
    public static let optionality = PropertyOptionKey<ParameterOptionNameSpace, Optionality>()
}
