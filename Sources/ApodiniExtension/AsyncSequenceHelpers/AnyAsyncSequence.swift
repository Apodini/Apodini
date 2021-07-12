//
//  AnyAsyncSequence.swift
//  
//
//  Created by Max Obermeier on 11.07.21.
//

import _Concurrency

@available(macOS 12.0, *)
public struct AnyAsyncSequence<Element>: AsyncSequence {
    public typealias AsyncIterator = AsyncIteratorImpl
    
    let _makeAsyncIterator: () -> AsyncIteratorImpl
    
    init<S>(_ sequence: S) where S: AsyncSequence, S.Element == Element {
        self._makeAsyncIterator = {
            AsyncIteratorImpl(sequence.makeAsyncIterator())
        }
    }
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        _makeAsyncIterator()
    }
}

@available(macOS 12.0, *)
extension AnyAsyncSequence {
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

@available(macOS 12.0, *)
public extension AsyncSequence {
    var typeErased: AnyAsyncSequence<Element> {
        AnyAsyncSequence(self)
    }
}
