//
//  DebugAsyncSequence.swift
//  
//
//  Created by Max Obermeier on 12.07.21.
//

import Foundation
import _Concurrency


public struct DebugAsyncSequence<Base>: AsyncSequence where Base: AsyncSequence {
    public typealias Element = Base.Element
    
    public typealias AsyncIterator = AsyncIteratorImpl
    
    let base: Base
    
    let onMake: (Base.AsyncIterator) -> Void
    
    let onNext: () -> Void
    
    let afterNext: (Base.Element?) -> Void
    
    let onError: (Error) -> Void
    
    init(_ base: Base, onMake: @escaping (Base.AsyncIterator) -> Void, onNext: @escaping () -> Void, afterNext: @escaping (Base.Element?) -> Void, onError: @escaping (Error) -> Void) {
        self.base = base
        self.onMake = onMake
        self.onNext = onNext
        self.afterNext = afterNext
        self.onError = onError
    }
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        let iterator = base.makeAsyncIterator()
        onMake(iterator)
        return AsyncIteratorImpl(iterator: iterator, onNext: onNext, afterNext: afterNext, onError: onError)
    }
}

extension DebugAsyncSequence {
    public struct AsyncIteratorImpl: AsyncIteratorProtocol {
        var iterator: Base.AsyncIterator
        
        let onNext: () -> Void
        
        let afterNext: (Base.Element?) -> Void
        
        let onError: (Error) -> Void
        
        public mutating func next() async throws -> Element? {
            do {
                onNext()
                let result = try await iterator.next()
                afterNext(result)
                return result
            } catch {
                onError(error)
                throw error
            }
        }
    }
}

public extension AsyncSequence {
    func debug(onMake: @escaping (Self.AsyncIterator) -> Void, onNext: @escaping () -> Void, afterNext: @escaping (Self.Element?) -> Void, onError: @escaping (Error) -> Void) -> DebugAsyncSequence<Self> {
        DebugAsyncSequence(self, onMake: onMake, onNext: onNext, afterNext: afterNext, onError: onError)
    }
}

