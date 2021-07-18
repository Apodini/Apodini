//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

//
//  InformationSet.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

/// An ``InformationSet`` is used to store ``Information`` instances, checked for uniqueness
/// against their ``InformationKey``.
public struct InformationSet {
    private var storage: [AnyHashable: AnyInformation] = [:]

    fileprivate init(_ storage: [AnyHashable: AnyInformation]) {
        self.storage = storage
    }

    mutating func insert<I: Information>(_ information: I) {
        storage[information.key] = information
    }

    mutating func insert<I: InformationInstantiatable>(_ instantiatable: I) {
        self.insert(instantiatable.untyped())
    }
}

// MARK: InformationSet+init
extension InformationSet {
    /// Initializes a new ``InformationSet`` form a preexisting array of ``AnyInformation``.
    /// - Parameter information: The array of ``AnyInformation``.
    public init(_ information: [AnyInformation]) {
        for info in information {
            info.collect(&self)
        }
    }

    /// Initializes a new ``InformationSet`` form a preexisting array of elements conforming to ``AnyInformation``.
    /// - Parameter information: The array of elements conforming ``AnyInformation``.
    public init<Element: AnyInformation>(_ information: [Element]) {
        for info in information {
            info.collect(&self)
        }
    }
}

// MARK: ExpressibleByArrayLiteral
extension InformationSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: AnyInformation...) {
        self.init(elements)
    }
}

// MARK: Subscripts
public extension InformationSet {
    /// Returns the value of an ``Information`` instance based on the passed ``InformationInstantiatable`` type.
    /// - Parameter key: The ``InformationInstantiatable`` type that is requested.
    /// - Returns: An instance of ``InformationInstantiatable/Value`` if an according ``Information``
    ///     is contained in the `InformationSet`.
    subscript<I: InformationInstantiatable>(_ instantiatable: I.Type = I.self) -> I.Value? {
        storage[AnyHashable(I.key)]?
            .typed(to: I.AssociatedInformation.self)
            .typed(instantiatable)?
            .value
    }

    /// Returns the value associated with a given ``InformationKey``.
    /// - Parameter key: The `InformationKey` to retrieve the value for.
    /// - Returns: The value of type ``InformationKey/Value`` associated with the  ``InformationKey``, if present.
    subscript<I: InformationKey>(_ key: I) -> I.RawValue? {
        guard let value = storage[AnyHashable(key)]?.value else {
            return nil
        }
        guard let castedValue = value as? I.RawValue else {
            fatalError("\(Self.self)[\(key)] -> \(I.RawValue?.self): Unexpected error occurred trying to cast value of type '\(type(of: value))'")
        }

        return castedValue
    }
}

// MARK: Sequence
extension InformationSet: Sequence {
    public typealias Iterator = Dictionary<AnyHashable, AnyInformation>.Values.Iterator

    public func makeIterator() -> Iterator {
        storage.values.makeIterator()
    }
}

// MARK: Collection
extension InformationSet: Collection {
    public typealias Index = Dictionary<AnyHashable, AnyInformation>.Index
    public typealias Element = Dictionary<AnyHashable, AnyInformation>.Value

    public var startIndex: Index {
        storage.values.startIndex
    }
    public var endIndex: Index {
        storage.values.endIndex
    }
    public subscript(position: Index) -> Element {
        storage.values[position]
    }

    public func index(after index: Index) -> Index {
        storage.values.index(after: index)
    }
}

// MARK: SetAlgebra
extension InformationSet {
    /// Returns a new ``InformationSet`` with the elements of both this set and the given one.
    /// - Parameter other: The other ``InformationSet``
    /// - Returns: A new ``InformationSet`` with the values of both, while the other sets overrides existing Information.
    public func union(_ other: [AnyInformation]) -> Self {
        InformationSet(storage.merging(InformationSet(other).storage) { _, new in
            new
        })
    }
}
