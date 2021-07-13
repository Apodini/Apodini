//
//  AsyncMergeSequence.swift
//  
//
//  Created by Max Obermeier on 12.07.21.
//

import Foundation
import _Concurrency

@available(macOS 12.0, *)
public struct AsyncMergeSequence<Base, Other>: AsyncSequence where Base: AsyncSequence, Other: AsyncSequence, Base.Element == Other.Element {
    public typealias AsyncIterator = AsyncIteratorImpl
    
    public typealias Element = Base.Element
    
    let base: Base
    let other: Other
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        AsyncIteratorImpl(base: base.makeAsyncIterator(), other: other.makeAsyncIterator())
    }
}

@available(macOS 12.0, *)
extension AsyncMergeSequence {
    public class AsyncIteratorImpl: AsyncIteratorProtocol {
        private var base: Base.AsyncIterator?
        private var other: Other.AsyncIterator?
        
        private var latestBase: Result<Element, Error>?
        private var latestOther: Result<Element, Error>?
        
        private var baseBusy = false
        private var otherBusy = false
        
        private var continuation: CheckedContinuation<Element?, Error>?
        
        // until actors can resume continuations we just use a good old mutex
        private let _lock = NSRecursiveLock()
        
        init(base: Base.AsyncIterator, other: Other.AsyncIterator) {
            self.base = base
            self.other = other
        }
        
        public func next() async throws -> Element? {
            _lock.lock()
            
            if let latestBase = latestBase {
                self.latestBase = nil
                _lock.unlock()
                return try latestBase.get()
            }
            
            if let latestOther = latestOther {
                self.latestOther = nil
                _lock.unlock()
                return try latestOther.get()
            }
            
            if base == nil && other == nil {
                _lock.unlock()
                return nil
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                _lock.unlock()
                
                Task {
                    _lock.lock()
                    guard var base = self.base, !baseBusy else {
                        _lock.unlock()
                        return
                    }
                    baseBusy = true
                    _lock.unlock()
                    do {
                        let next = try await base.next()
                        _lock.lock()
                        if self.base != nil {
                            self.base = base
                            baseBusy = false
                        }
                        _lock.unlock()
                        self.handle(result: .success(next), base: true)
                    } catch {
                        self.handle(result: .failure(error), base: true)
                    }
                }
                
                Task {
                    _lock.lock()
                    guard var other = self.other, !otherBusy else {
                        _lock.unlock()
                        return
                    }
                    otherBusy = true
                    _lock.unlock()
                    do {
                        let next = try await other.next()
                        _lock.lock()
                        if self.other != nil {
                            self.other = other
                            otherBusy = false
                        }
                        _lock.unlock()
                        self.handle(result: .success(next), base: false)
                    } catch {
                        self.handle(result: .failure(error), base: false)
                    }
                }
            }
        }
        
        private func handle(result: Result<Element?, Error>, base: Bool) {
            _lock.lock()
            
            switch result {
            case let .failure(error):
                self.base = nil
                self.other = nil
                
                if let continuation = continuation {
                    self.continuation = nil
                    _lock.unlock()
                    continuation.resume(throwing: error)
                    return
                } else {
                    if base {
                        self.latestBase = .failure(error)
                    } else {
                        self.latestOther = .failure(error)
                    }
                    _lock.unlock()
                    return
                }
            case let .success(result):
                if result == nil {
                    if base {
                        self.base = nil
                    } else {
                        self.other = nil
                    }
                }
                
                if let continuation = self.continuation {
                    if let value = result {
                        self.continuation = nil
                        _lock.unlock()
                        continuation.resume(returning: value)
                        return
                    } else if self.base == nil && self.other == nil {
                        self.continuation = nil
                        _lock.unlock()
                        continuation.resume(returning: nil)
                        return
                    }
                } else {
                    if let value = result {
                        if base {
                            self.latestBase = .success(value)
                        } else {
                            self.latestOther = .success(value)
                        }
                    }
                    _lock.unlock()
                    return
                }
            }
            _lock.unlock()
        }
    }
}

@available(macOS 12.0, *)
public extension AsyncSequence {
    func merge<Other>(with other: Other) -> AsyncMergeSequence<Self, Other> where Other: AsyncSequence, Self.Element == Other.Element {
        AsyncMergeSequence(base: self, other: other)
    }
}
