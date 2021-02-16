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

