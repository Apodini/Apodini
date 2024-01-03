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

    /// Returns the untyped version of the ``AnyInformation`` instance. This method has no effect on ``Information``
    /// instances and returns self. For ``InformationInstantiatable`` it returns the corresponding ``Information`` instance.
    /// - Returns: The untyped ``AnyInformation``.
    func anyUntyped() -> any AnyInformation

    /// Type erased version of the ``Information/merge(with:)-1xjd0`` and ``InformationInstantiatable/merge(with:)-66dae`` methods.
    ///
    /// Default implementations exists for both protocols.
    ///
    /// - Parameter information: The ``AnyInformation`` to merge with.
    /// - Returns: The resulting ``AnyInformation``.
    func anyMerge(with information: any AnyInformation) -> any AnyInformation
}

internal extension AnyInformation {
    /// Returns the type version of the ``AnyInformation`` instance.
    ///
    /// - Parameter type: The ``AnyInformation`` type
    /// - Returns: Returns the casted ``AnyInformation`` instance.
    func typed<T: AnyInformation>(to type: T.Type = T.self) -> T {
        guard let typed = self as? T else {
            fatalError("Tried typing AnyInformation with type \(self) to \(T.self)")
        }

        return typed
    }
}
