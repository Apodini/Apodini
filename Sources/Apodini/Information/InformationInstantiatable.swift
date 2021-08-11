//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// A ``InformationInstantiatable`` represents type implementation of a predefined
/// ``Information`` instance for a fixed ``InformationKey``.
@dynamicMemberLookup
public protocol InformationInstantiatable: AnyInformation {
    /// The associated ``Information`` from which value this `InformationInstantiatable` can be derived.
    associatedtype AssociatedInformation: Information

    /// The value represented by this ``InformationInstantiatable``.
    /// Typically this represents a type based version of the ``InformationKey/RawValue`` type of the
    //  ``InformationInstantiatable/AssociatedInformation``
    associatedtype Value

    /// The statically defined ``InformationKey`` of the ``InformationInstantiatable/AssociatedInformation``
    /// which identifies any ``InformationInstantiatable`` conforming instance.
    static var key: AssociatedInformation.Key { get }

    /// The raw value retrieved from a the associated ``InformationInstantiatable/AssociatedInformation``
    var rawValue: AssociatedInformation.Key.RawValue { get }

    /// The value derived from the ``InformationInstantiatable/rawValue`` from the associated ``Information`` instance.
    var value: Value { get }

    /// Required initializer to instantiate a new ``InformationInstantiatable`` from
    /// the rawValue captured by an ``Information`` instance.
    /// - Parameter rawValue: The raw value as captured by the ``Information``
    init?(rawValue: AssociatedInformation.Key.RawValue)

    /// Required initializer to instantiate a new ``InformationInstantiatable`` from the typed value.
    /// - Parameter value: The value ``Value``.
    init(_ value: Value)

    /// Enables developers to directly access properties of the `value`
    /// property using the ``InformationInstantiatable``.
    subscript<Member>(dynamicMember keyPath: KeyPath<Value, Member>) -> Member { get }
}

// MARK: dynamicMemberLookup
public extension InformationInstantiatable {
    /// Enables developers to directly access properties of the ``InformationInstantiatable/value``
    /// property using the ``InformationInstantiatable``.
    subscript<Member>(dynamicMember keyPath: KeyPath<Value, Member>) -> Member {
        value[keyPath: keyPath]
    }
}

// MARK: AnyInformation
public extension InformationInstantiatable {
    /// Provides the type erased value as required by ``AnyInformation``

    var value: Any {
        rawValue
    }
}

// MARK: AnyInformation+InformationVisitor
public extension InformationInstantiatable {
    /// Default implementation accepting an ``InformationSet`` as required by ``AnyInformation``
    func collect(_ set: inout InformationSet) {
        set.insert(self)
    }
}

// MARK: Information
extension InformationInstantiatable {
    /// Internal method to create the appropriate ``InformationInstantiatable/AssociatedInformation`` instance.
    func untyped() -> AssociatedInformation {
        AssociatedInformation(key: Self.key, rawValue: rawValue)
    }
}
