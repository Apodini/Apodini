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


extension Collection where Element: Hashable {
    public func compareIgnoringOrder<C>(
        _ other: C,
        computeHash: @escaping (Element, inout Hasher) -> Void,
        areEqual: (Element, Element) -> Bool
    ) -> Bool where C: Collection, C.Element == Element {
        guard self.count == other.count else {
            return false
        }
        
        return compareEqualsIgnoringOrder(
            lhs: self.distinctElementCounts(computeHash: computeHash, areEqual: areEqual),
            rhs: other.distinctElementCounts(computeHash: computeHash, areEqual: areEqual),
            areEqual: { areEqual($0.0, $1.0) && $0.1 == $1.1 }
        )
    }
    
    
    // yeah this probably has awful performance...
    // main issue (and this is the reason why all of this exists in the first place)
    // is that we versions of the `compareIgnoringOrder` and `distinctElementCounts` functions
    // which work witout having to rely on `Element`'s `hash` and `==` implementations.
    // another issue: this function can't return a dictionary (or use one anywhere in its implementation),
    // the reason being that that would call Element's hash/== implementations, which is the very thing we're trying to avoid here...
    // also, the `computeHash` argument's @escaping is not actually needed (the closure never leaves the function's scope) but local closures are implicitly @escaping (which can't be overwritten) and `withoutActuallyEscaping` doesn't work :/
    private func distinctElementCounts(
        computeHash: @escaping (Element, inout Hasher) -> Void,
        areEqual: (Element, Element) -> Bool
    ) -> [(element: Element, count: Int)] {
        let hash: (Element) -> Int = { element in
            var hasher = Hasher()
            computeHash(element, &hasher)
            return hasher.finalize()
        }
        var retval: [(element: Element, count: Int)] = []
        for element in self {
            if let idx = retval.firstIndex(where: { hash($0.element) == hash(element) && areEqual($0.element, element) }) {
                retval[idx].count += 1
            } else {
                retval.append((element, 1))
            }
        }
        return retval
    }
}


/// "Equals" implementation for two collections of 2-element tuples where both tuple element types are Equatable.
public func == <C0: Collection, C1: Collection, Key: Equatable, Value: Equatable> (
    lhs: C0,
    rhs: C1
) -> Bool where C0.Element == (Key, Value), C1.Element == (Key, Value) {
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


/// "Unordered equals" implementation for two collections of 2-element tuples using a custom equality predicate.
/// - Note: this assumes that `areEqual` is symmetric.
public func compareEqualsIgnoringOrder<C0: Collection, C1: Collection, Key, Value> (
    lhs: C0,
    rhs: C1,
    areEqual: ((Key, Value), (Key, Value)) -> Bool
) -> Bool where C0.Element == (Key, Value), C1.Element == (Key, Value) {
    guard lhs.count == rhs.count else {
        return false
    }
    
    var rhs = Array(rhs)
    
    for entry in lhs {
        guard let idx = rhs.firstIndex(where: { areEqual(entry, $0) }) else {
            // we're unable to find a matching key-value pair in rhs,
            // meaning this entry exists only in lhs, meaning the two collections are not equal
            return false
        }
        rhs.remove(at: idx)
    }
    return true
}


extension RandomAccessCollection {
    /// Safely access the element at the specified index.
    /// - returns: the element at `idx`, if `idx` is a valid index for subscripting into the collection, otherwise `nil`.
    public subscript(safe idx: Index) -> Element? {
        indices.contains(idx) ? self[idx] : nil
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
