//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// An ``Information`` can be used to map arbitrary middleware specific Metadata into Apdoini,
/// and make them accessible inside an ``Handler``.
/// 
/// Every ``Information`` instance is uniquely identified by a ``InformationKey``.
/// ``Information`` instances are stored in the ``InformationSet`` of a `Request` or ``Response``.
///
/// The following examples assume the existence of `ExampleInformation` (which is a ``InformationInstantiatable``)
/// and `AnyExampleInformation` sharing the key `ExampleInformationKey`.
/// Additionally we assume the custom defined subscript overload on the ``InformationSet`` `InformationSet[example: String]`.
///
/// ## Retrieving Information instances
/// ```swift
/// struct ExampleHandler: Handler {
///     @Environment(\.connection) var connection: Connection
///
///     func handle() -> String {
///         let information = connection.information
///
///         let info1 = information[ExampleInformation.self] // returns the typed ExampleInformation.Value if present
///         let info2 = information[example: "dynamicKey"] // use custom overload to return raw value for the dynamic key (assuming string key)
///         let info3 = information[ExampleInformationKey("dynamicKey")] // same as above, just not using the custom overload
///
///         return "Hello World"
///     }
/// }
/// ```
///
/// ## Returning Information instances
/// ```swift
/// struct ExampleHandler: Handler {
///     func handle() -> Response<String> {
///         // either instantiate a `InformationSet` by hand (e.g. via array literal)
///         // or pass them directly into the response like presented here
///
///         return .final(
///             "Hello World",
///             information: ExampleInformation(.someTypedValue), AnyExampleInformation(key: "dynamic", value: "custom")
///         )
///     }
/// }
/// ```
///
/// Note: A ``Information`` instance **must** conform to at least one ``InformationClass``.
///     Refer to ``InformationClass`` for more information.
@dynamicMemberLookup
public protocol Information: AnyInformation where Self: InformationClass {
    /// The ``InformationKey`` type uniquely identified this ``Information`` instance.
    associatedtype Key: InformationKey

    /// The ``InformationKey`` instance identifying the ``Information``.
    var key: Self.Key { get }

    /// The value associated with the type implementing ``Information``
    var value: Key.RawValue { get }

    /// Initializes the ``Information`` from its respective ``Key`` and the corresponding ``InformationKey/RawValue``.
    /// - Parameters:
    ///   - key: The respective ``Key`` instance.
    ///   - rawValue: The respective ``InformationKey/RawValue``.
    init(key: Key, rawValue: Key.RawValue) // TODO were this one renamed to `init(key:value:)`, it could be satisfied using the default synthesised initialiser for structs!

    /// Initializes the ``Information`` from its respective ``InformationKey/KeyValue`` and the corresponding ``InformationKey/RawValue``.
    /// Not a default initializer is provided based on ``init(key:rawValue:)``
    /// - Parameters:
    ///   - key: The respective ``InformationKey/KeyValue`` instance.
    ///   - rawValue: The respective ``InformationKey/RawValue``.
    init(key: Key.KeyValue, rawValue: Key.RawValue)

    /// This method can be used to instantiate a ``InformationInstantiatable`` from the contents of this `Information`.
    /// - Parameter instantiatable: The instantiatable type to be used.
    /// - Returns: The instance of the provided ``InformationInstantiatable``.
    func typed<Instantiatable: InformationInstantiatable>(_ instantiatable: Instantiatable.Type) -> Instantiatable?
        where Instantiatable.AssociatedInformation == Self

    /// Merges this ``Information`` instance with the provided instance.
    /// The ``Information`` instance passed in as the parameter has a higher precedence.
    /// The default implementation will merge by overriding.
    /// - Parameter information: The ``Information`` to merge with.
    /// - Returns: The merged ``Information`` instance.
    func merge(with information: Self) -> Self

    /// Enables developers to directly access properties of the ``value-4ijxx`` property using the ``Information``.
    subscript<Member>(dynamicMember keyPath: KeyPath<Key.RawValue, Member>) -> Member { get }
}

// MARK: dynamicMemberLookup
public extension Information {
    /// Enables developers to directly access properties of the ``value-4ijxx`` property using the ``Information``.
    subscript<Member>(dynamicMember keyPath: KeyPath<Key.RawValue, Member>) -> Member {
        value[keyPath: keyPath]
    }
}

public extension Information {
    /// Default implementation, merging by overriding.
    func merge(with information: Self) -> Self {
        information
    }

    /// Default implementation using the default ``InformationInstantiatable/init(rawValue:)``
    /// to instantiate the provided ``InformationInstantiatable``.
    func typed<Instantiatable: InformationInstantiatable>(_ instantiatable: Instantiatable.Type) -> Instantiatable?
        where Instantiatable.AssociatedInformation == Self {
        Instantiatable(rawValue: value)
    }
}

// MARK: Information+defaultInit
public extension Information {
    /// Default initializer based on ``Information/init(key:rawValue:)``
    /// Initializes the ``Information`` from its respective ``InformationKey/KeyValue`` and the corresponding ``InformationKey/RawValue``.
    /// - Parameters:
    ///   - key: The respective ``InformationKey/KeyValue`` instance.
    ///   - rawValue: The respective ``InformationKey/RawValue``.
    init(key: Key.KeyValue, rawValue: Key.RawValue) {
        self.init(key: Key(key), rawValue: rawValue)
    }
}

// MARK: AnyInformation
public extension Information {
    /// Provides the type erased value as required by ``AnyInformation``
    var value: Any {
        value as Key.RawValue
    }

    /// Returns `self`
    func anyUntyped() -> AnyInformation {
        self
    }

    /// Default implementation. Forwards to ``Information/merge(with:)``.
    /// If types don't match, the passed value will override the current Information.
    func anyMerge(with information: AnyInformation) -> AnyInformation {
        if let selfInformation = information as? Self {
            return merge(with: selfInformation)
        }
        return information
    }
}

// MARK: AnyInformation+InformationVisitor
public extension Information {
    /// Default implementation accepting an ``InformationSet`` as required by ``AnyInformation``
    func collect(_ set: inout InformationSet) {
        set.insert(self)
    }
}
