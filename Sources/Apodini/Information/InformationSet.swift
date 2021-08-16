//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import ApodiniUtils

/// An ``InformationSet`` is used to store ``Information`` instances, checked for uniqueness
/// against their ``InformationKey``.
public struct InformationSet {
    private var storage: [AnyHashable: AnyInformation] = [:]
    /// Pretty much acts a typed cache for the above storage dict.
    /// For every key contained in this dictionary, there is a according untyped value preset above.
    /// The other way around doesn't hold.
    private var capturedInstantiatables: [AnyHashable: AnyInformation] = [:]

    fileprivate init(_ storage: [AnyHashable: AnyInformation], _ instantiatables: [AnyHashable: AnyInformation]) {
        self.storage = storage
        self.capturedInstantiatables = instantiatables
    }

    mutating func insert<I: Information>(_ information: I) {
        assertTypeIsStruct(I.self, messagePrefix: "Information") // avoid mutability

        let key = AnyHashable(information.key)
        storage[key] = information
        capturedInstantiatables.removeValue(forKey: key) // ensures no outdated information is present
    }

    mutating func insert<I: InformationInstantiatable>(_ instantiatable: I) {
        assertTypeIsStruct(I.self, messagePrefix: "InformationInstantiatable") // avoid mutability

        let key = AnyHashable(I.key)

        storage[key] = instantiatable.untyped()
        capturedInstantiatables[key] = instantiatable
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
        let key = AnyHashable(I.key)

        if let captured = capturedInstantiatables[key] as? I {
            return captured.value
        }

        return storage[AnyHashable(I.key)]?
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
    /// - Parameter other: The other array of ``AnyInformation``
    /// - Returns: A new ``InformationSet`` with the values of both, while the other sets overrides existing Information.
    public func merge(with other: [AnyInformation]) -> Self {
        merge(with: InformationSet(other))
    }

    /// Returns a new ``InformationSet`` with the elements of both this set and the given one.
    /// - Parameter other: The other ``InformationSet``
    /// - Returns: A new ``InformationSet`` with the values of both, while the other sets overrides existing Information.
    public func merge(with other: InformationSet) -> Self {
        var storage = storage.merging(other.storage) { existing, new in
            existing.anyMerge(with: new)
        }
        let instantiatables = capturedInstantiatables.merging(other.capturedInstantiatables) { existing, new in
            existing.anyMerge(with: new)
        }

        for instantiatable in instantiatables {
            // merging of typed versions has higher precedence than the untyped version
            storage[instantiatable.key] = instantiatable.value.anyUntyped()
        }

        return InformationSet(storage, instantiatables)
    }
}
