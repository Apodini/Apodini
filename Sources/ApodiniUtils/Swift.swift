//
//  Swift.swift
//  
//
//  Created by Lukas Kollmer on 16.02.21.
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
    
    
    /// Insert an element into the set, using the provided closure to merge the element with an existing element, if applicable
    /// - parameter newElement: The element to be inserted into the receiver
    /// - parameter mergingFn: The closure to be called if the set already contains an element matching `newElement`
    public mutating func insert(_ newElement: Element, merging mergingFn: (_ oldElem: Element, _ newElem: Element) -> Element) {
        if let idx = firstIndex(of: newElement) {
            update(with: mergingFn(self[idx], newElement))
        } else {
            insert(newElement)
        }
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
    
    
    /// Count the number of elements matching `predicate`
    public func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        try reduce(into: 0) { $0 += try predicate($1) ? 1 : 0 }
    }
    
    
    /// Returns the first element after the specified index, which matches the predicate
    public func first(after idx: Index, where predicate: (Element) throws -> Bool) rethrows -> Element? {
        try firstIndex(from: index(after: idx), where: predicate).map { self[$0] }
    }
    
    
    /// Returns the first index within the collection which matches a predicate, starting one after the specified index.
    public func firstIndex(after idx: Index, where predicate: (Element) throws -> Bool) rethrows -> Index? {
        try firstIndex(from: index(after: idx), where: predicate)
    }
    
    /// Returns the first index within the collection which matches a predicate, starting at `from`.
    public func firstIndex(from idx: Index, where predicate: (Element) throws -> Bool) rethrows -> Index? {
        guard indices.contains(idx) else {
            return nil
        }
        if try predicate(self[idx]) {
            return idx
        } else {
            return try firstIndex(from: index(after: idx), where: predicate)
        }
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
    /// Checks whether the collectionn consists of the same elements as the other collection, ignoring the actual order of the elements.
    /// The purpose of this function is that it can be used with non-hashable and non-equatable collections
    /// (also hashable and equatable collections, but in a way that ignores the default hashable/equatable implementation).
    /// - parameter other: The other collection to compare with.
    /// - parameter computeHash: A function used to hash an element.
    /// - parameter areEqual: A function used to determine whether two elements are equal.
    /// - Note: There is also an `compareIgnoringOrder<C>(_:)` function which uses the element's
    ///         default `Hashable` and `Equatable` conformances instead of requiring the two closure parameters.
    ///         In most cases that's probably what you're looking for.
    public func compareIgnoringOrder<C>(
        _ other: C,
        computeHash: (Element, inout Hasher) -> Void,
        areEqual: (Element, Element) -> Bool
    ) -> Bool where C: Collection, C.Element == Element {
        guard self.count == other.count else {
            return false
        }
        
        func computeDistinctCounts<C: Collection>(_ value: C) -> [(C.Element, Int)] where C.Element == Element {
            value
                .distinctElementCounts(computeHash: computeHash, areEqual: areEqual)
                .map { ($0.element, $0.count) }
        }
        
        return computeDistinctCounts(self).compareEqualsIgnoringOrder(
            computeDistinctCounts(other),
            areEqual: { areEqual($0.0, $1.0) && $0.1 == $1.1 }
        )
    }
    
    
    /// Determine how many distinct elements the collection contains, and how often each of these distinct elements is in the collection.
    /// This function serves as an alternative to `distinctElementCounts() -> [Element: Int]`.
    /// The main difference is that this function does not require `Element` be `Hashable` or `Equatable`. In fact, if they are, these conformances are ignored entirely.
    /// Instead, these two operations can be customised by passing closures.
    /// - returns:  An array of `(element, count)` key-value pairs.
    ///             This function has to return an `Array`, since construcing a `Dictionary<Element, Int>` from the array
    ///             would require `Element` conform to `Hashable`, which is the very thing this function is here to avoid.
    /// - parameter computeHash: A function used to hash an element.
    /// - parameter areEqual: A function used to determine whether two elements are equal.
    /// - Note: There is alao another version of this function (`distinctElementCounts()`) which uses the element's `Hashable` and `Equatable` conformances,
    ///         instead of requiring the two closure parameters.
    private func distinctElementCounts(
        computeHash: (Element, inout Hasher) -> Void,
        areEqual: (Element, Element) -> Bool
    ) -> [(element: Element, count: Int)] {
        func hash(_ element: Element) -> Int {
            var hasher = Hasher()
            computeHash(element, &hasher)
            return hasher.finalize()
        }
        var retval: [(element: Element, count: Int)] = []
        for element in self {
            let elementHash = hash(element)
            if let idx = retval.firstIndex(where: { hash($0.element) == elementHash && areEqual($0.element, element) }) {
                retval[idx].count += 1
            } else {
                retval.append((element, 1))
            }
        }
        return retval
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


extension Collection {
    /// "Unordered equals" implementation for two collections of 2-element tuples using a custom equality predicate.
    /// - Note: this assumes that `areEqual` is symmetric.
    public func compareEqualsIgnoringOrder<Other: Collection, T0, T1> (
        _ other: Other,
        areEqual: ((T0, T1), (T0, T1)) -> Bool
    ) -> Bool where Self.Element == (T0, T1), Other.Element == (T0, T1) {
        guard self.count == other.count else {
            return false
        }
        
        var other = Array(other)
        
        for entry in self {
            guard let idx = other.firstIndex(where: { areEqual(entry, $0) }) else {
                // we're unable to find a matching tuple in rhs,
                // meaning this entry exists only in lhs, meaning the two collections are not equal
                return false
            }
            other.remove(at: idx)
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
        fmt.dateFormat = formatString
        return fmt.string(from: self)
    }
}
