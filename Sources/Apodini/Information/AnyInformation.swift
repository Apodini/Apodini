//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// Describes a type erased version of an ``Information`` instance.
public protocol AnyInformation {
    /// Returns the type erased value of a ``Information``.
    var value: Any { get }

    /// Accepts a ``InformationSet`` instance which is used to collect the given ``AnyInformation``.
    /// - Parameter visitor: The ``InformationSet`` which should collect this instance.
    func collect(_ set: inout InformationSet)
}

internal extension AnyInformation {
    /// Returns the type version of the ``AnyInformation`` instance.
    /// - Parameter type: The ``AnyInformation`` type
    /// - Returns: Returns the casted ``AnyInformation`` instance.
    func typed<T: AnyInformation>(to type: T.Type = T.self) -> T {
        guard let typed = self as? T else {
            fatalError("Tried typing AnyInformation with type \(self) to \(T.self)")
        }

        return typed
    }
}
