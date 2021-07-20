//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// Uniquely identifies a `Information` instance.
///
/// Note, when you create a new ``InformationKey`` you might want to add a custom subscript overload
/// to the ``InformationSet``.
/// By default the ``InformationSet`` exposes a subscript allowing to query the value of an ``Information``
/// by providing an instance of an ``InformationKey``.
/// Considering the key `ExampleStringInformationKey` one might query it like the following:
/// ```swift
/// let information: InformationSet = ...
/// let value = information[ExampleStringInformationKey("keyValue")]
/// ```
///
/// To make it easier for users to dynamically query a given ``Information`` define a custom subscript like the following:
/// ```swift
/// public extension InformationSet {
///     // all such declarations must expose an external parameter name
///     subscript(example key: String) -> String? {
///         self[ExampleStringInformationKey(key)]
///     }
/// }
///
/// // results in the following query
/// let information: InformationSet = ...
/// let value = information[example: "keyValue"]
/// ```
public protocol InformationKey: Hashable {
    /// The type of the raw key value identifying the ``Information``.
    associatedtype KeyValue: Hashable
    /// The raw value associated with the implementation ``Information`` type.
    associatedtype RawValue

    /// The raw value identifying the ``Information``.
    var key: KeyValue { get }

    /// Initialize a new ``InformationKey`` instance by providing the according
    /// ``InformationKey/KeyValue`` value.
    /// - Parameter key: The identifier value.
    init(_ key: KeyValue)
}

extension InformationKey {
    /// Default `Equatable` implementation.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key
    }

    /// Default `Hashable` implementation.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(Self.self))
        hasher.combine(key)
    }
}
