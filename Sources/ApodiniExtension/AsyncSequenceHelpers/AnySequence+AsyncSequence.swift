//
//  AnySequence+AsyncSequence.swift
//  
//
//  Created by Max Obermeier on 11.07.21.
//

import _Concurrency

extension AnySequence: AsyncSequence {
    public typealias AsyncIterator = AsyncIteratorImpl
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        AsyncIteratorImpl(iterator: self.makeIterator())
    }
}

extension AnySequence {
    public struct AsyncIteratorImpl: AsyncIteratorProtocol {
        var iterator: AnySequence.Iterator
        
        public mutating func next() async throws -> Element? {
            iterator.next()
        }
    }
}

public extension Sequence {
    /// Wraps this `Sequence` in an `AnySequence`, which in turn can be used
    /// as an `AsyncSequence`.
    var asAsyncSequence: AnySequence<Element> {
        AnySequence(self)
    }
}
