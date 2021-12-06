//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


/// A Stack data structure, i.e. a "first in last out" queue
public struct Stack<Element> {
    private var storage: [Element]
    
    /// Creates a new, empty stack
    public init() {
        storage = []
    }
    
    /// Creates a new stack, filled with the elements in the other sequence
    public init<S>(_ other: S) where S: Sequence, S.Element == Element {
        storage = Array(other)
    }
    
    /// Whether the stack is currently empty
    public var isEmpty: Bool { storage.isEmpty }
    
    /// The number of elements currently in the stack
    public var count: Int { storage.count }
    
    /// Pushes a new element onto the stack
    public mutating func push(_ element: Element) {
        storage.append(element)
    }
    
    /// Removes the element currently on the top of the stack
    /// - returns: The removed element, or `nil` if the stack is empty
    @discardableResult
    public mutating func pop() -> Element? {
        guard !isEmpty else {
            return nil
        }
        return storage.removeLast()
    }
    
    /// Returns the stack's current top element, or `nil` if the stack is empty
    public func peek() -> Element? {
        storage.last
    }
}


extension Stack: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}


extension Stack: Collection {
    public typealias Index = Array<Element>.Index
    
    public var startIndex: Index {
        storage.startIndex
    }
    
    public var endIndex: Index {
        storage.endIndex
    }
    
    public subscript(index: Index) -> Element {
        storage[index]
    }
    
    public func index(after idx: Index) -> Index {
        storage.index(after: idx)
    }
}


extension Stack {
    /// Checks whether a stack of `Any.Type` objects contains some specific type.
    public func contains(_ other: Element) -> Bool where Element == Any.Type {
        let identifier = ObjectIdentifier(other)
        return contains { ObjectIdentifier($0) == identifier }
    }
}
