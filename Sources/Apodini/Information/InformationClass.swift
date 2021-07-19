//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// A ```InformationClass``` is a way to group multiple, similar ``Information`` types
/// which represent the same Metadata information and can be mapped to the same type of
/// key and value.
///
/// A ``InformationClass`` is typically defined for a specific ``InterfaceExporter`` or a group
/// of ``InterfaceExporter``s sharing the same middleware.
/// An ``InterfaceExporter`` uses an predefined ``InformationClass`` to collect all ``Information`` instances
/// which shall be mapped to a certain wire format feature (in both direction). HTTP Headers are one example for that.
///
/// Below examples consider the example of a `AnyExampleInformation` (conforming to ``Information``) which is
/// identified by a `String` and has a value of type `String`.
///
/// ## Defining a new ``InformationClass``
/// While ``InformationClass`` protocol doesn't explicitly define any requirements (to avoid associated types requirements constraints),
/// all implementations should follow the same style to be consistent.
///
/// ```swift
/// public protocol ExampleInformationClass: InformationClass {
///     var entry: (key: String, value: String) { get }
/// }
/// ```
///
/// The `entry` tuple matches the key and value types.
///
/// ## Declaring a ``Information`` to be part of a ``InformationClass``
/// Now we want to declare the `AnyExampleInformation` to be part of the above-defined `ExampleInformationClass`.
///
/// ```swift
/// // declaring protocol conformance
/// extension AnyExampleInformation: ExampleInformationClass {}
///
/// // We declare the actual implementation of the class as an extension on the `InformationClass` itself.
/// // This allows us to avoid any name conflicts on the `entry` property when conforming to multiple information classes.
/// public extension ExampleInformationClass where Self == AnyExampleInformation {
///     var entry: (key: String, value: String) {
///         (key: self.key.key, value: self.value)
///     }
/// }
/// ```
///
/// ## Filtering the ``InformationSet`` for a given ``InformationClass``
/// An exporter could filter for a dedicated ``InformationClass`` like the following:
///
/// ```swift
/// for (key, value) in information
///     .compactMap({ $0 as? HTTPHeaderInformationClass })
///     .map({ $0.entry }) {
///     // operate on the tuple
/// }
/// ```
public protocol InformationClass {}
