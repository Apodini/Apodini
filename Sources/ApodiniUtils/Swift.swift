//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation


// MARK: Set

extension Set {
    /// Forms the union of two sets
    public static func + (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }
    
    /// Forms the union of a set and a sequence
    public static func + <S> (lhs: Self, rhs: S) -> Self where S: Sequence, S.Element == Self.Element {
        lhs.union(rhs)
    }
    
    /// Forms the union of a sequence and a set
    public static func + <S> (lhs: S, rhs: Self) -> Self where S: Sequence, S.Element == Self.Element {
        rhs.union(lhs)
    }
    
    /// Insert an element into the set
    public static func += (lhs: inout Set<Element>, rhs: Element) {
        lhs.insert(rhs)
    }
    
    /// Insert a sequence of elements into the set
    public static func += <S> (lhs: inout Self, rhs: S) where S: Sequence, S.Element == Element {
        lhs.formUnion(rhs)
    }
}


// MARK: Array

extension Array {
    /// Returns a copy of the array, with the specified element appended to the end.
    public func appending(_ element: Element) -> [Element] {
        var copy = self
        copy.append(element)
        return copy
    }
    
    /// Returns a copy of the array, with the specified elements appended to the end.
    public func appending<S>(contentsOf elements: S) -> [Element] where S: Sequence, S.Element == Element {
        var copy = self
        copy.append(contentsOf: elements)
        return copy
    }
    
    /// Sorts the array in-place, using a key path
    public mutating func sort<T: Comparable>(by keyPath: KeyPath<Element, T>) {
        self = sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
}


// MARK: Sequence

extension Sequence {
    /// Returns the elements of the sequence, sorted using the given key path to a comparable value
    /// as the comparison between elements.
    /// - Parameter keyPath: A key path to a value of an element, that is comparable.
    /// - Returns: A sorted array.
    public func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>, ascending: Bool = true) -> [Element] {
        let sorted = self.sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
        return ascending ? sorted : sorted.reversed()
    }
    
    
    /// Returns the elements of the sequence, as an array consisting only of nonnull elements.
    /// - Note: This only removes one level of nullability. If you have nested optionals, you'll have to take care of that separately.
    public func dropNilValues<T>() -> [T] where Element == T? {
        self.compactMap { $0 }
    }
    
    /// Returns a set created by mapping the elements of the sequence using the specified block
    public func mapIntoSet<Result: Hashable>(_ transform: (Element) throws -> Result) rethrows -> Set<Result> {
        var retval = Set<Result>()
        retval.reserveCapacity(self.underestimatedCount)
        for element in self {
            retval.insert(try transform(element))
        }
        return retval
    }
    
    /// Returns a `Dictionary` constructed from the key-value pairs returned by the `transform` closure
    public func mapIntoDict<Key: Hashable, Value>(_ transform: (Element) throws -> (Key, Value)) rethrows -> [Key: Value] {
        var retval: [Key: Value] = [:]
        for element in self {
            let (key, value) = try transform(element)
            retval[key] = value
        }
        return retval
    }
    
    /// Returns a set created by compact-mapping the elements of the sequence using the specified block
    public func compactMapIntoSet<Result: Hashable>(_ transform: (Element) throws -> Result?) rethrows -> Set<Result> {
        var retval = Set<Result>()
        retval.reserveCapacity(self.underestimatedCount / 2)
        for element in self {
            if let mapped = try transform(element) {
                retval.insert(mapped)
            }
        }
        return retval
    }
    
    
    /// Returns the number of elements in the sequence that satisfy the predicate.
    public func count(where predicate: (Element) -> Bool) -> Int {
        var retval = 0
        for element in self {
            if predicate(element) {
                retval += 1
            }
        }
        return retval
    }
    
    
    /// Creates an array by consuming all of the sequence's elements.
    public func intoArray() -> [Element] {
        Array(self)
    }
    
    /// Creates a Set by consuming all of the sequence's elements.
    public func intoSet() -> Set<Element> where Element: Hashable {
        Set(self)
    }
}


// MARK: Collection

extension Collection {
    /// Reduces the collection using the specified closure, using the first element as the initial value
    public func reduceIntoFirst(_ transform: (inout Element, Element) throws -> Void) rethrows -> Element? {
        guard let first = self.first else {
            return nil
        }
        return try dropFirst().reduce(into: first, transform)
    }
    
    /// Reduces the collection using the specified closure, using the first element as the initial value
    public func reduceIntoFirst(_ transform: (Element, Element) throws -> Element) rethrows -> Element? {
        guard let first = self.first else {
            return nil
        }
        return try dropFirst().reduce(first, transform)
    }
    
    /// Returns the index of the first element after the specified `otherIdx` for which the preducate evaluates to true
    public func firstIndex(after otherIdx: Index, where predicate: (Element) throws -> Bool) rethrows -> Index? {
        for idx in indices[otherIdx...] {
            if try predicate(self[idx]) {
                return idx
            }
        }
        return nil
    }
    
    /// Returns the index of the first element which compares equal to the specied element after the specified `otherIdx`
    public func firstIndex(of element: Element, after otherIdx: Index) -> Index? where Element: Equatable {
        firstIndex(after: otherIdx, where: { $0 == element })
    }
}


extension Collection where Element: Hashable {
    /// Returns `true` if the two collections contain the same elements, regardless of their order.
    /// - Note: this is different from `Set(self) == Set(other)`, insofar as this also
    ///         takes into account how often an element occurs, which the Set version would ignore
    public func compareIgnoringOrder<C>(_ other: C) -> Bool where C: Collection, C.Element == Element {
        guard self.count == other.count else {
            return false
        }
        // important here is that this must be an unordered compare (e.g. by comparing dictionaries)
        return self.distinctElementCounts() == other.distinctElementCounts()
    }
    
    /// Returns a dictionary containing the dictinct elements of the collection (ie, without duplicates) as the keys, and each element's occurrence count as value
    public func distinctElementCounts() -> [Element: Int] {
        reduce(into: [:]) { result, element in
            result[element] = (result[element] ?? 0) + 1
        }
    }
}


extension Collection {
    /// Compares two collections of 2-element tuples where both tuple element types are Equatable.
    public static func == <Other: Collection, Key: Equatable, Value: Equatable> (
        lhs: Self,
        rhs: Other
    ) -> Bool where Self.Element == (Key, Value), Other.Element == (Key, Value) {
        guard lhs.count == rhs.count else {
            return false
        }
        for (lhsVal, rhsVal) in zip(lhs, rhs) {
            guard lhsVal == rhsVal else {
                return false
            }
        }
        return true
    }
}


extension RandomAccessCollection {
    /// Safely access the element at the specified index.
    /// - returns: the element at `idx`, if `idx` is a valid index for subscripting into the collection, otherwise `nil`.
    public subscript(safe idx: Index) -> Element? {
        indices.contains(idx) ? self[idx] : nil
    }
}


extension RangeReplaceableCollection {
    /// Initialises the collection and reserves the specified capacity.
    public init(reservingCapacity capacity: Int) {
        self.init()
        self.reserveCapacity(capacity)
    }
}


// MARK: Date

extension Date {
    /// Formats the date using the ISO8601 date format, optionally including the current time.
    public func formatAsIso8601(includeTime: Bool = false) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        if includeTime {
            fmt.formatOptions.formUnion([.withTime])
        }
        return fmt.string(from: self)
    }

    /// Formats the date using the supplied format string.
    public func format(_ formatString: String) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US")
        fmt.dateFormat = formatString
        return fmt.string(from: self)
    }
}


extension Array {
    /// Returns a string descriptioin of the elements of this array,
    /// containing as many elements as fit until the resulting string exceeds `maxLength` characters.
    public func description(maxLength: Int) -> String {
        guard !isEmpty else {
            return "[]"
        }
        var desc = "["
        for (idx, element) in self.enumerated() {
            if idx != startIndex {
                desc.append(", ")
            }
            let elementDesc = String(describing: element)
            if desc.count + elementDesc.count + 1 > maxLength {
                // The resulting string would be too large, don't add the desc
                return desc + ", ...]"
            } else {
                desc += ", \(elementDesc)"
            }
        }
        return desc + "]"
    }
    
    /// Removes the first occurrence of the specified object from the array.
    /// - returns: The index from which the object was removed, `nil` if the object was not found in the array
    @discardableResult
    public mutating func removeFirstOccurrence(of element: Element) -> Int? where Element: Equatable {
        if let idx = firstIndex(of: element) {
            remove(at: idx)
            return idx
        } else {
            return nil
        }
    }
    
    /// Removes from the array the first element for which the predicate evaluates to true.
    /// - returns: The index from which the matching element was removed, `nil` if none of the array's elements matched the predicate.
    @discardableResult
    public mutating func removeFirstOccurrence(where predicate: (Element) -> Bool) -> Int? {
        if let idx = firstIndex(where: predicate) {
            remove(at: idx)
            return idx
        } else {
            return nil
        }
    }
    
    /// Performs an in-place removal of all elements in the array that are also in the specified other sequence.
    public mutating func subtract<S>(_ other: S) where Element: Hashable, S: Sequence, S.Element == Element {
        let otherAsSet = Set(other)
        self = filter { !otherAsSet.contains($0) }
    }
    
    
    /// Performs an in-place map operation.
    public mutating func mapInPlace(_ transform: (inout Element) throws -> Void) rethrows {
        for idx in indices {
            var element = self[idx]
            try transform(&element)
            self[idx] = element
        }
    }
    
    /// Appends `newElement` to the array, unless an element comparing equal to `newElement` already exists in the array.
    public mutating func appendUnlessPresent(_ newElement: Element) where Element: Equatable {
        if !contains(newElement) {
            append(newElement)
        }
    }
}


private struct ThreeValueHashable<A: Hashable, B: Hashable, C: Hashable>: Hashable {
    let a: A // swiftlint:disable:this identifier_name
    let b: B // swiftlint:disable:this identifier_name
    let c: C // swiftlint:disable:this identifier_name
}


extension Array {
    /// Performs an in-place removal of all elements in the array that are also in the specified other sequence.
    public mutating func subtract<S, A, B>(_ other: S) where Element == (A, B), S: Sequence, S.Element == (A, B), A: Hashable, B: Hashable {
        let otherAsSet = other.mapIntoSet { ThreeValueHashable(a: $0.0, b: $0.1, c: 0 as UInt8) }
        self = filter { !otherAsSet.contains(ThreeValueHashable(a: $0.0, b: $0.1, c: 0 as UInt8)) }
    }
    
    /// Performs an in-place removal of all elements in the array that are also in the specified other sequence.
    public mutating func subtract<S, A, B, C>(
        _ other: S
    ) where Element == (A, B, C), S: Sequence, S.Element == (A, B, C), A: Hashable, B: Hashable, C: Hashable { // swiftlint:disable:this large_tuple
        let otherAsSet = other.mapIntoSet { ThreeValueHashable(a: $0.0, b: $0.1, c: $0.2) }
        self = filter { !otherAsSet.contains(ThreeValueHashable(a: $0.0, b: $0.1, c: $0.2)) }
    }
}


// MARK: Result

extension Result {
    /// Whether the result is a success
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// Whether the result is a failure
    public var isFailure: Bool {
        switch self {
        case .failure:
            return true
        case .success:
            return false
        }
    }
}


// MARK: Dictionary

extension Dictionary {
    /// Creates a new Dictionary by mapping the values of this dictionary.
    public func mapValues<NewValue>(_ transform: (Key, Value) throws -> NewValue) rethrows -> [Key: NewValue] {
        var retval: [Key: NewValue] = [:]
        for (key, value) in self {
            retval[key] = try transform(key, value)
        }
        return retval
    }
}


// MARK: Comparable

extension Comparable {
    /// Performs a three-way comparison between `self` and `other`, with the receiver acting as the comparison's left operand and `other` acting as its right operand.
    public func compareThreeWay(_ other: Self) -> ComparisonResult {
        if self < other {
            return .orderedAscending
        } else if self == other {
            return .orderedSame
        } else {
            return .orderedDescending
        }
    }
}
