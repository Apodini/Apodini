//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation
import _Concurrency

public struct AsyncMergeSequence<Base, Other>: AsyncSequence where Base: AsyncSequence, Other: AsyncSequence, Base.Element == Other.Element {
    public typealias AsyncIterator = AsyncIteratorImpl
    
    public typealias Element = Base.Element
    
    let base: Base
    let other: Other
    
    public func makeAsyncIterator() -> AsyncIteratorImpl {
        AsyncIteratorImpl(base: base.makeAsyncIterator(), other: other.makeAsyncIterator())
    }
}

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
                    await requestNextOnBaseIfNecessary()
                }
                
                Task {
                    await requestNextOnOtherIfNecessary()
                }
            }
        }
        
        private func requestNextOnBaseIfNecessary() async {
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
                self.handleResultFromBase(result: .success(next))
            } catch {
                _lock.unlock()
                self.handleResultFromBase(result: .failure(error))
            }
        }
        
        private func requestNextOnOtherIfNecessary() async {
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
                self.handleResultFromOther(result: .success(next))
            } catch {
                _lock.unlock()
                self.handleResultFromOther(result: .failure(error))
            }
        }
        
        private func handleResultFromBase(result: Result<Element?, Error>) {
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
                    self.latestBase = .failure(error)
                    _lock.unlock()
                    return
                }
            case let .success(result):
                if result == nil {
                    self.base = nil
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
                        self.latestBase = .success(value)
                    }
                    _lock.unlock()
                    return
                }
            }
            _lock.unlock()
        }
        
        private func handleResultFromOther(result: Result<Element?, Error>) {
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
                    self.latestOther = .failure(error)
                    _lock.unlock()
                    return
                }
            case let .success(result):
                if result == nil {
                    self.other = nil
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
                        self.latestOther = .success(value)
                    }
                    _lock.unlock()
                    return
                }
            }
            _lock.unlock()
        }
    }
}

public extension AsyncSequence {
    /// An asynchronous sequence that merges the elements from the base sequence with those from the `other`
    /// sequence.
    ///
    /// There is no fixed precedence between the two upstream sequence's elements. Instead, whenever
    /// a new element is requested by the downstream sequence, both upstreams get the change to provide an element.
    /// The one that returns first is handed downstream immediately, the other is stored to be returned when the
    /// downstream requests the next element.
    func merge<Other>(with other: Other) -> AsyncMergeSequence<Self, Other> where Other: AsyncSequence, Self.Element == Other.Element {
        AsyncMergeSequence(base: self, other: other)
    }
}
