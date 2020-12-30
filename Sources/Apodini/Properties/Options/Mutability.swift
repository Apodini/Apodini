//
//  Mutability.swift
//
//
//  Created by Max Obermeier on 10.12.20.
//
import Foundation


/// A generic `PropertyOption` that indicates if the `@Parameter`'s value can be updated during the lifetime of its container once it has been set once.
public enum Mutability: PropertyOption {
    /// The `@Parameter` can be updated without restrictions.
    case variable
    /// The `@Parameter` cannot  be updated once it has been set. Default values can still be overridden.
    case constant
}

extension PropertyOptionKey where PropertyNameSpace == ParameterOptionNameSpace, Option == Mutability {
    static let mutability = PropertyOptionKey<ParameterOptionNameSpace, Mutability>()
}

extension AnyPropertyOption where PropertyNameSpace == ParameterOptionNameSpace {
    /// An HTTP specific option that indicates how the `@Parameter` property wrapper should be interpreted by interface exporters using HTTP to identify and multiplex components.
    public static func mutability(_ mode: Mutability) -> AnyPropertyOption<ParameterOptionNameSpace> {
        AnyPropertyOption(key: .mutability, value: mode)
    }
}
