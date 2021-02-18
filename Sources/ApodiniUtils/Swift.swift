//
//  Swift.swift
//  
//
//  Created by Lukas Kollmer on 16.02.21.
//

import Foundation



// MARK: Type-casting


/// Perform a dynamic cast from one type to another.
/// - returns: the casted value, or `nil` if the cast failed
/// - note: This is semantically equivalent to the `as?` operator.
///         The reason this function exists is to enable casting from `Any` to an optional type,
///         which is otherwise rejected by the type checker.
public func dynamicCast<U>(_ value: Any, to _: U.Type) -> U? {
    value as? U
}


// MARK: Set

extension Set {
    /// Forms the union of two sets
    public static func + (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }
    
    public static func + <S> (lhs: Self, rhs: S) -> Self where S: Sequence, S.Element == Self.Element {
        lhs.union(rhs)
    }
    
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
            insert(mergingFn(self[idx], newElement))
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
        return try firstIndex(from: index(after: idx), where: predicate).map { self[$0] }
    }
    
    
    public func firstIndex(after idx: Index, where predicate: (Element) throws -> Bool) rethrows -> Index? {
        return try firstIndex(from: index(after: idx), where: predicate)
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


extension RandomAccessCollection {
    /// Safely access the element at the specified index.
    /// - returns: the element at `idx`, if `idx` is a valid index for subscripting into the collection, otherwise `nil`.
    public subscript(lk_safe idx: Index) -> Element? {
        indices.contains(idx) ? self[idx] : nil
    }
}




// MARK: Date

extension Date {
    public func formatAsIso8601(includeTime: Bool = false) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        if includeTime {
            fmt.formatOptions.formUnion([.withTime])
        }
        return fmt.string(from: self)
    }
    
    public func format(_ formatString: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = formatString
        return fmt.string(from: self)
    }
}

