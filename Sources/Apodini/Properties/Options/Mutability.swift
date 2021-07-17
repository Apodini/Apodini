//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

/// A generic `PropertyOption` that indicates if the `@Parameter`'s value can be updated during the lifetime of its container once it has been set.
public enum Mutability: PropertyOption {
    /// The `@Parameter` can be updated without restrictions.
    case variable
    /// The `@Parameter` cannot  be updated once it has been set. Default values can still be overridden.
    case constant
}

extension PropertyOptionKey where PropertyNameSpace == ParameterOptionNameSpace, Option == Mutability {
    /// The ``PropertyOptionKey`` for ``Mutability`` of a ``Parameter``.
    public static let mutability = PropertyOptionKey<ParameterOptionNameSpace, Mutability>()
}

extension AnyPropertyOption where PropertyNameSpace == ParameterOptionNameSpace {
    /// A generic option that indicates if the `@Parameter`'s value can be updated during the lifetime of its container once it has been set.
    public static func mutability(_ mode: Mutability) -> AnyPropertyOption<ParameterOptionNameSpace> {
        AnyPropertyOption(key: .mutability, value: mode)
    }
}
