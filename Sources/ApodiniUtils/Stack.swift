//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


public struct Stack<Element> {
    private var storage: [Element]
    
    public init() {
        storage = []
    }
    
    public init<S>(_ other: S) where S: Sequence, S.Element == Element {
        storage = Array(other)
    }
    
    public var isEmpty: Bool { storage.isEmpty }
    public var count: Int { storage.count }
    
    public mutating func push(_ element: Element) {
        storage.append(element)
    }
    
    @discardableResult
    public mutating func pop() -> Element? {
        guard !isEmpty else {
            return nil
        }
        return storage.removeLast()
    }
    
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
