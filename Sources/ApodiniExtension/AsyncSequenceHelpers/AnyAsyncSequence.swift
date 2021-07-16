//
//  AnyAsyncSequence.swift
//  
//
//  Created by Max Obermeier on 11.07.21.
//

import _Concurrency

/// A type-erased version of a `AsyncSequence` that contains values of type `Element`.
public struct AnyAsyncSequence<Element>: AsyncSequence {
    public typealias AsyncIterator = AsyncIteratorImpl
    
    private let _makeAsyncIterator: () -> AsyncIteratorImpl
    
    init<S>(_ sequence: S) where S: AsyncSequence, S.Element == Element {
        self._makeAsyncIterator = {
            AsyncIteratorImpl(sequence.makeAsyncIterator())
        }
    }
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        _makeAsyncIterator()
    }
}

extension AnyAsyncSequence {
    /// The type-erased iterator implementation of ``AnyAsyncSequence``.
    public struct AsyncIteratorImpl: AsyncIteratorProtocol {
        private let _next: (Any) async throws -> (Any, Element?)
        private var iterator: Any
        
        init<I>(_ iterator: I) where I: AsyncIteratorProtocol, I.Element == Element {
            self.iterator = iterator
            self._next = { iterator in
                guard var iterator = iterator as? I else {
                    fatalError("Internal logic of 'AnyAsyncSequence' is broken. Incorrect typing.")
                }
                
                let next = try await iterator.next()
                return (iterator, next)
            }
        }
        
        public mutating func next() async throws -> Element? {
            let (iterator, next) = try await _next(self.iterator)
            self.iterator = iterator
            return next
        }
    }
}

public extension AsyncSequence {
    /// Erases the type from this `AsyncSequence` by wrapping it in an ``AnyAsyncSequence``.
    var typeErased: AnyAsyncSequence<Element> {
        AnyAsyncSequence(self)
    }
}
