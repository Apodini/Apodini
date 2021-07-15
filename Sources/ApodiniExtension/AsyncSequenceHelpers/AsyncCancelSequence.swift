//
//  AsyncCancelSequence.swift
//  
//
//  Created by Max Obermeier on 12.07.21.
//

import Foundation
import _Concurrency


public struct AsyncCancelSequence<Base>: AsyncSequence where Base: AsyncSequence {
    public typealias Element = Base.Element
    
    public typealias AsyncIterator = AsyncIteratorImpl
    
    let base: Base
    
    let cancel: (Base.Element) async -> Bool
    
    init(_ base: Base, cancel: @escaping (Base.Element) async -> Bool) {
        self.base = base
        self.cancel = cancel
    }
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        AsyncIteratorImpl(iterator: base.makeAsyncIterator(), cancel: cancel)
    }
}

extension AsyncCancelSequence {
    public struct AsyncIteratorImpl: AsyncIteratorProtocol {
        var iterator: Base.AsyncIterator?
        
        let cancel: (Base.Element) async -> Bool
        
        public mutating func next() async throws -> Element? {
            if let result = try await iterator?.next() {
                if await cancel(result) {
                    iterator = nil
                }
                return result
            }
            iterator = nil
            return nil
        }
    }
}

public extension AsyncSequence {
    func cancel(if cancel: @escaping (Self.Element) async -> Bool) -> AsyncCancelSequence<Self> {
        AsyncCancelSequence(self, cancel: cancel)
    }
}

