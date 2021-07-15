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
            return iterator.next()
        }
    }
}

public extension Sequence {
    var asAsyncSequence: AnySequence<Element> {
        AnySequence(self)
    }
}
